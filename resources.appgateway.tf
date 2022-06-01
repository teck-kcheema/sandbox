locals {
  backend_probe_name = "${azurerm_virtual_network.main.name}-probe"
  http_setting_name  = "${azurerm_virtual_network.main.name}-be-htst"
  public_ip_name     = "${azurerm_virtual_network.main.name}-pip"
}

resource "azurerm_public_ip" "main" {
  name                = local.public_ip_name
  resource_group_name = var.resource_group
  location            = var.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "kcheema-sandbox"
}

resource "azurerm_application_gateway" "network" {
  depends_on          = [azurerm_public_ip.main]
  name                = "kcheema-appgateway-sandbox"
  resource_group_name = var.resource_group
  location            = var.resource_group_location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.main.0.id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agw.id]
  }

  dynamic "frontend_port" {
    for_each = azurerm_app_service.main
    content {
      name = "${azurerm_virtual_network.main.name}-${frontend_port.value.name}-feport"
      port = "808${frontend_port.key}"
    }
  }

  frontend_ip_configuration {
    name                 = "${azurerm_virtual_network.main.name}-feip"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  dynamic "backend_address_pool" {
    for_each = azurerm_app_service.main
    content {
      name  = "${azurerm_virtual_network.main.name}-${backend_address_pool.value.name}-beap"
      fqdns = [backend_address_pool.value.default_site_hostname]
    }
  }

  probe {
    name                                      = local.backend_probe_name
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 120
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    match {
      body        = "Welcome"
      status_code = [200, 399]
    }
  }

  backend_http_settings {
    name                                = local.http_setting_name
    probe_name                          = local.backend_probe_name
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 120
    pick_host_name_from_backend_address = true
  }

  dynamic "http_listener" {
    for_each = azurerm_app_service.main
    content {
      name                           = "${azurerm_virtual_network.main.name}-${http_listener.value.name}-httplstn"
      frontend_ip_configuration_name = "${azurerm_virtual_network.main.name}-feip"
      frontend_port_name             = "${azurerm_virtual_network.main.name}-${http_listener.value.name}-feport"
      protocol                       = "Https"
      ssl_certificate_name           = "ssl"
    }
  }

  ssl_certificate {
    name                            = "ssl"
    data                            = filebase64("appgwcert.pfx")
    password                        = "Azure123456!"
  }
  
  trusted_client_certificate {
    name                            = "client"
    data                            = filebase64("root0.cer")
  }

  dynamic "ssl_profile" {
    for_each = azurerm_app_service.main
    content {
      name                          = "${azurerm_virtual_network.main.name}-mtlsauthedsslprofile"
      trusted_client_certificate_names = ["client"]
    }
  }
  dynamic "request_routing_rule" {
    for_each = azurerm_app_service.main
    content {
      name                       = "${azurerm_virtual_network.main.name}-${request_routing_rule.value.name}-rqrt"
      priority                   = 10
      rule_type                  = "Basic"
      http_listener_name         = "${azurerm_virtual_network.main.name}-${request_routing_rule.value.name}-httplstn"
      backend_address_pool_name  = "${azurerm_virtual_network.main.name}-${request_routing_rule.value.name}-beap"
      backend_http_settings_name = local.http_setting_name
    }
  }
}