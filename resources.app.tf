locals {
  app_services = [
    {
      kind = "Linux"
      sku = {
        tier = "Standard"
        size = "S1"
      }
    }
  ]
}

resource "azurerm_app_service_plan" "main" {
  name                = "kcheema-app-service-plan-sandbox"
  location            = var.resource_group_location
  resource_group_name = var.resource_group
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "main" {
  count               = length(local.app_services)
  name                = "kcheema-appservice-sandbox"
  location            = var.resource_group_location
  resource_group_name = var.resource_group
  app_service_plan_id = azurerm_app_service_plan.main.id

  site_config {
    dotnet_framework_version = "v4.0"
    remote_debugging_enabled = true
    remote_debugging_version = "VS2019"
  }
}