resource "azurerm_application_gateway" "appgw" {
  name                = var.appgw_name
  location            = var.location
  resource_group_name = var.rg_name
  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
    # capacity field is not needed with autoscaling
  }

  # Matlab: Jitni zyada traffic aayegi, utne zyada App Gateway instances banenge
  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = data.azurerm_subnet.appgw_sub.id
  }

  frontend_port {
    name = var.frontend_port_name # "frontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name # "frontendIP"
    public_ip_address_id = data.azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name         = var.backend_address_pool_name #"backendPool"
    #ip_addresses = [data.azurerm_network_interface.nic1.private_ip_address, data.azurerm_network_interface.nic2.private_ip_address]
  }

probe {
  name        = var.healthProbe
  protocol    = "Http"
  path        = "/"
  interval    = 30
  timeout     = 30
  unhealthy_threshold = 3
  pick_host_name_from_backend_http_settings = true  # ✅ Set to true
  # host = "" → ❌ Remove this

  match {
    status_code = [200]
  }
}

  backend_http_settings {
    name                                = var.http_setting_name
    protocol                            = "Http"
    port                                = 80
    cookie_based_affinity               = "Disabled"
    request_timeout                     = 30
    probe_name                          = var.healthProbe
    pick_host_name_from_backend_address = true
    # Remove or don't define host_name
  }

  http_listener {
    name                           = var.http_listener_name #  "httpListener"
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

request_routing_rule {
  name                       = var.request_routing_rule_name
  rule_type                  = "Basic"
  http_listener_name         = var.http_listener_name
  backend_address_pool_name  = var.backend_address_pool_name
  backend_http_settings_name = var.http_setting_name
  priority                   = 100  # ✅ Add this line

}
}