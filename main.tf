terraform{
    required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id            = var.subscription_id
}

# Resource Group is already defined in your environment
# Using "1-4a99e6fb-playground-sandbox" as referenced in your earlier code

# 1. Create a Virtual Network and Subnet for integration
resource "azurerm_virtual_network" "vnet" {
  name                = "bestrong-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "integration_subnet" {
  name                 = "integration-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  # This delegation is required for App Service VNet integration
  delegation {
    name = "app-service-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# 2. Create the Service Plan (modern replacement for App Service Plan)
resource "azurerm_service_plan" "service_plan" {
  name                = "bestrong-plan"
  location            = "eastus"
  resource_group_name = var.resource_group_name
  os_type             = "Windows" # Or "Linux" depending on your needs
  sku_name            = "S1"      # Standard tier as specified in your original code
}

# 3. Create the App Service with VNet integration and System Managed Identity
resource "azurerm_windows_web_app" "app" { # Use azurerm_linux_web_app for Linux
  name                = "bestrong-app"
  location            = "eastus"
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.service_plan.id

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  site_config {
    # Add any necessary site configuration here
    application_stack {
      current_stack  = "dotnet" # Adjust based on your application stack
      dotnet_version = "v6.0"   # Adjust based on your .NET version
    }
  }
}

# 4. Configure VNet integration for the App Service
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_windows_web_app.app.id
  subnet_id      = azurerm_subnet.integration_subnet.id
}

resource "azurerm_application_insights" "insights" {
  name                = "bestrong-insights"
  location            = "eastus"
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = null # Set to a Log Analytics workspace ID if you have one
  retention_in_days   = 90
}

resource "azurerm_container_registry" "acr" {
  name                = "bestrongacr"
  resource_group_name = var.resource_group_name
  location            = "eastus"
  sku                 = "Basic"
  admin_enabled       = false
}
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_windows_web_app.app.identity[0].principal_id
}



# 5. Output the managed identity principal ID (useful for granting permissions)
output "managed_identity_principal_id" {
  value       = azurerm_windows_web_app.app.identity[0].principal_id
  description = "The Principal ID of the System Assigned Managed Identity"
}

output "app_url" {
  value       = "https://${azurerm_windows_web_app.app.default_hostname}"
  description = "The URL of the deployed App Service"
}