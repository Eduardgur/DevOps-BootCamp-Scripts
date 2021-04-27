locals{
    server_name_suffix = "postgers-server",
    server_sku = "GP_Gen5_2",
    server_version = "11",
    server_storage_mb = "5120"
    server_ssl_enforcment = false,
    db_name_suffix = "postgers-database",
    db_charset = "UTF8",
    db_collation = "English_United States.1252",
    db_network_rule_name = "Postgres-VNet-Rule",
    db_network_rule_ignore_missing_vnet_service_endpoint = true,
    db_private_endpoint = "Private-Endpoint"
    db_private_service_connection_name_suffix = "Private-Service-Connection",
    db_private_service_connection_subresource_names = ["postgresqlServer"],
    db_private_service_connection_is_manual_connection = false

}

#Create Postgresql server 
resource "azurerm_postgresql_server" "server" {
  name                = "${local.name}-${local.server_name_suffix}"
  resource_group_name = local.rg_name
  location            = local.location

  administrator_login          = var.server_admin_username
  administrator_login_password = var.server_admin_password

  sku_name   = local.server_sku
  version    = local.server_version
  storage_mb = local.server_storage_mb

  ssl_enforcement_enabled = local.server_ssl_enforcments
}

#Create Postgresql server
resource "azurerm_postgresql_database" "database" {
  name                = "${local.name}-${local.db_name_suffix}"
  resource_group_name = local.rg_name

  server_name = azurerm_postgresql_server.server.name
  charset     = local.db_charset
  collation   = local.db_collation
}

#Configure Postgresql network
resource "azurerm_postgresql_virtual_network_rule" "db_server_vnet_configuration" {
  name                = local.name
  resource_group_name = local.rg_name

  server_name                          = azurerm_postgresql_server.server.name
  subnet_id                            = local.server_subnet_id
  ignore_missing_vnet_service_endpoint = local.db_network_rule_ignore_missing_vnet_service_endpoint
}

#Create a private endpoint for the server
resource "azurerm_private_endpoint" "server_private_endpoint" {
  name                = "${local.name}-${local.db_private_endpoint}"
  resource_group_name = local.rg_name
  location            = local.location

  subnet_id = local.server_subnet_id
  private_service_connection {
    name                           = "${local.name}-${local.db_private_service_connection}"
    private_connection_resource_id = azurerm_postgresql_server.server.id
    subresource_names              = local.db_private_service_connection_subresource_names
    is_manual_connection           = local.db_private_service_connection_is_manual_connection
  }
}


