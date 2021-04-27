locals{
    name= "BackEnd"
    nsg_rule_db_name                        = "Allow-Postgres-All"
    nsg_rule_db_priority                    = 103
    nsg_rule_db_direction                   = "Inbound"
    nsg_rule_db_access                      = "Allow"
    nsg_rule_db_protocol                    = "Tcp"
    nsg_rule_db_source_address_prefix       = "Internet"
    nsg_rule_db_source_port_range           = "5432"
    nsg_rule_db_destination_port_range      = "5432"
}


#Create nework for the back end
module "network" {
    source = "../../network/basic_network"

    location = var.location
    rg_name = var.rg_name
    name = "${var.name}-${local.name}"
    subnet_cidr = var.subnet_cidr
}

#Create postgresql server
module "postgresql" {
    source = "../../services/postgresql"

    location = var.location
    rg_name = var.rg_name
    name = "${var.name}-${local.name}"
    server_admin_username = local.admin_username
    server_admin_password = local.admin_password
    server_subnet_id = basic_network.network.subnet_id
}

#Creates NSG rule for the backend - allow tcp 5432 from frontend subnet to backend subnet
resource "azurerm_network_security_rule" "postgres_nsg_rule" {
  name                         = "${var.name}-${local.name}"
  resource_group_name          = local.rg_name
  network_security_group_name  = azurerm_network_security_group.DbNsg.name
  priority                     = local.nsg_rule_db_priority
  direction                    = local.nsg_rule_db_direction
  access                       = local.nsg_rule_db_access
  protocol                     = local.nsg_rule_db_protocol
  source_address_prefixes      = var.inbound_address_prefixes
  source_port_range            = local.nsg_rule_db_source_port_range
  destination_address_prefixes = var.subnet_cidr
  destination_port_range       = local.nsg_rule_db_destination_port_range
}

