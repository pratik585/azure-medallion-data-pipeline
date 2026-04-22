variable "sql_password" {}
variable "azure_ad_admin_user" {}
variable "azure_ad_admin_object_id" {}
variable "my_public_ip" {}

# =====================================
# RESOURCE GROUP
# =====================================
data "azurerm_resource_group" "rg" {
  name = "<resource-group>"
}

# =====================================
# SQL SERVER
# =====================================
resource "azurerm_mssql_server" "sql_server" {
  name                          = "waterqualityserverproject12"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = "West US 2"
  version                       = "12.0"
  administrator_login           = "sqladminuser"
  administrator_login_password  = var.sql_password

  azuread_administrator {
    login_username = var.azure_ad_admin_user
    object_id      = var.azure_ad_admin_object_id
  }

  public_network_access_enabled = true
}

# =====================================
# SQL DATABASE
# =====================================
resource "azurerm_mssql_database" "sql_db" {
  name                        = "water-quality-db"
  server_id                   = azurerm_mssql_server.sql_server.id
  sku_name                    = "Basic"
  max_size_gb                 = 2
  zone_redundant              = false
}

# =====================================
# SQL FIREWALL RULE (allow client IP)
# =====================================
resource "azurerm_mssql_firewall_rule" "allow_local_machine" {
  name             = "AllowClientIP"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = var.my_public_ip
  end_ip_address   = var.my_public_ip
}


#####################################
# Azure Blob Storage Account
#####################################
resource "azurerm_storage_account" "blob" {
  name                     = "waterqualitybs1"      # must be globally unique
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Blob storage type
  account_kind              = "StorageV2"

  blob_properties {
    delete_retention_policy {
      days = 1
    }
    container_delete_retention_policy {
      days = 1
    }
  }
}

#####################################
# Azure Blob Storage Container
#####################################
resource "azurerm_storage_container" "blob_container" {
  name                 = "water-quality-container"
  storage_account_id   = azurerm_storage_account.blob.id   # FIXED (no deprecated name)
  container_access_type = "private"
}

#####################################
#Azure ADLS Gen2 Storage Account
#####################################
resource "azurerm_storage_account" "adls" {
  name                     = "waterqualityaccountadls"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Enable Data Lake Gen2 (Data Lake namespace)
  is_hns_enabled = true        # <--- Correct attribute

  blob_properties {
    versioning_enabled = false   # default (same as no retention)
  }

  share_properties {}            # Required but empty when retention disabled
}

#####################################
# Azure Data Lake Storage Container
#####################################
resource "azurerm_storage_container" "adls_container" {
  name                 = "adfdata"
  storage_account_id   = azurerm_storage_account.adls.id
  container_access_type = "private"
}

#####################################
# Logic App Standard
#####################################

############################################
# SERVICE PLAN for Logic App Standard
#############################################
resource "azurerm_service_plan" "logicapp_plan" {
  name                = "waterquality-la-plan"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  os_type  = "Windows"
  sku_name = "WS1"
}

#############################################
# STORAGE ACCOUNT for Logic App metadata
#############################################
resource "azurerm_storage_account" "logicapp_storage" {
  name                     = "waterqualitylasab001"   # must be globally unique
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

#############################################
# LOGIC APP STANDARD
#############################################
resource "azurerm_logic_app_standard" "logicapp" {
  name                        = "water-quality-logicapp"
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  app_service_plan_id         = azurerm_service_plan.logicapp_plan.id
  storage_account_name        = azurerm_storage_account.logicapp_storage.name
  storage_account_access_key  = azurerm_storage_account.logicapp_storage.primary_access_key

  version = "~4"   # Correct Functions runtime version

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "0"
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet-isolated"
  }
}




#############################################
# DATA FACTORY
#############################################
resource "azurerm_data_factory" "adf" {
  name                = "adf-medallion-project-1234"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "development"
  }
}


#########################################################
# DATABRICKS WORKSPACE
#########################################################
resource "azurerm_databricks_workspace" "databricks" {
  name                = "water-quality-databricks"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  sku = "standard"     # UI default (used for jobs, clusters, ML, notebooks)
  managed_resource_group_name = "${data.azurerm_resource_group.rg.name}-dbworkspace-rg"
}
