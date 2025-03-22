output "storage_account_primary_key" {
  value     = azurerm_storage_account.example.primary_access_key
  sensitive = true
}

output "mysql_server_name" {
  value = azurerm_mysql_flexible_server.example.name
}

output "mysql_admin_username" {
  value = azurerm_mysql_flexible_server.example.administrator_login
}

output "mysql_admin_password" {
  value     = azurerm_mysql_flexible_server.example.administrator_password
  sensitive = true
}

output "mysql_host" {
  value = azurerm_mysql_flexible_server.example.fqdn
}
