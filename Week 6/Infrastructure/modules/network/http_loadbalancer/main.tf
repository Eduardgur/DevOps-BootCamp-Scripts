#Creates loadbalancer for the frontend
locals {
    ip_suffix = "Public-Ip"
    public_ip_allocation_method = "Static"
    public_ip_allocation_sku = "standard"
    lb_suffix = "LoadBalancer"
    lb_sku = "standard"
    lb_frontend_ip_name = "public"
    lb_pool_name = "App-LB-BeckEnd-Pool"
    lb_rule_name = "HTTP-LB-Rule"
    lb_rule_protocol = "Tcp"
    lb_rule_front = "80"
    lb_rule_back = "8080"
    lb_prob_name = "HTTP-Probe"
    lb_prob_protocol = "http"
    lb_prob_port = "8080"
    lb_prob_request_path = "/"
    lb_prob_number_of_probes = "5"
    lb_nat_rule_name = "SSH-LB-NAT-Rule"
    lb_nat_rule_protocol = "Tcp"
    lb_nat_rule_front_port_prefix = "6500"
    lb_nat_rule_back_port = "22"
    lb_nat_rule_frontend_ip_configuration_name = "SSH-LB-NAT-Rule"
    lb_nat_rule_ = "SSH-LB-NAT-Rule"
}

#Create public ip
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.name}-${local.ip_suffix}"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = local.public_ip_allocation_method
  sku                 = local.public_ip_allocation_sku
}

#Create load balancer
resource "azurerm_lb" "loadbalancer" {
  name                = "${var.name}-${local.lb_suffix}"
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = local.lb_sku

  frontend_ip_configuration {
    name                 = local.lb_frontend_ip_name
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

#Creates backend ip pool for the frontend loadbalancer 
resource "azurerm_lb_backend_address_pool" "app_lb_backend_pool" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = local.lb_pool_name
}

#Creates loadbalancer rule for the frontend - tcp 80
resource "azurerm_lb_rule" "app_http_lb_rule" {
  resource_group_name            = var.rg_name
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = local.lb_rule_name
  protocol                       = local.lb_rule_protocol
  frontend_ip_configuration_name = local.lb_frontend_ip_name
  frontend_port                  = local.lb_rule_front
  backend_port                   = local.lb_rule_back
  backend_address_pool_id        = azurerm_lb_backend_address_pool.app_lb_backend_pool.id
  probe_id                       = azurerm_lb_probe.app_http_prob.id
}

#Creates loadbalancer prob for the frontend - 80
resource "azurerm_lb_probe" "app_http_prob" {
  resource_group_name            = var.rg_name
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  name                = local.lb_prob_name
  protocol            = local.lb_prob_protocol
  port                = local.lb_prob_port
  request_path        = local.lb_prob_request_path
  number_of_probes    = local.lb_prob_number_of_probes
}

#Create lb nat rule to allow ssh
resource "azurerm_lb_nat_rule" "app_lb_nat_rule" {
  count = var.lb_nat_rule_count
  
  resource_group_name            = var.rg_name
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "${local.lb_nat_rule_name}-${count.index}"
  protocol                       = local.lb_nat_rule_protocol
  frontend_port                  = "${local.lb_nat_rule_front_port_prefix}${count.index}"
  backend_port                   = local.lb_nat_rule_back_port
  frontend_ip_configuration_name = local.lb_frontend_ip_name
  // depends_on                     = [local.nic_id]
}