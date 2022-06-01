locals {
  cidr_block = "10.254.0.0/16"
  subnets = {
    frontend = cidrsubnet(local.cidr_block, 8, 0)
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "main-network"
  resource_group_name = var.resource_group
  location            = var.resource_group_location
  address_space       = [local.cidr_block]
}

resource "azurerm_subnet" "main" {
  count                = length(keys(local.subnets))
  name                 = keys(local.subnets)[count.index]
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.subnets[keys(local.subnets)[count.index]]]
}