resource "azurerm_mysql_flexible_server" "example" {
  name                = "tchak-mysql"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name            = "B_Standard_B1ms"
  version             = "8.0.21"

  administrator_login    = "adminuser"
  administrator_password = "SuperSecret123!"
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false

  storage {
    size_gb = 20  
  }
}
