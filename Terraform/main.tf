# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}


# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "tchak-rg2"
  location = "Central US"

}

# Create a virtual network within the resource group
resource "azurerm_public_ip" "example" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

# 🔹 Création du réseau virtuel (VNet)
resource "azurerm_virtual_network" "example" {
  name                = "tchak-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"] # Plage d'adresses du VNet

  tags = {
    environment = "Production"
  }
}

# 🔹 Création d'un sous-réseau (Subnet) dans le VNet
resource "azurerm_subnet" "example" {
  name                 = "tchak-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"] # Plage d'adresses du sous-réseau
}

resource "azurerm_ssh_public_key" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.example.name 
  location            = azurerm_resource_group.example.location
  public_key          = file("~/.ssh/id_rsa.pub")
}


# Création d'une interface réseau
resource "azurerm_network_interface" "example" {
  name                = "tchak-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "tchak-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  # Référence correcte à l'interface réseau
  network_interface_ids = [azurerm_network_interface.example.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "tchakstorageacc"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Production"
  }

  depends_on = [azurerm_resource_group.example]
}

resource "azurerm_storage_container" "example" {
  name                  = "tchak-container"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"  # "private" = accès sécurisé

  depends_on = [azurerm_storage_account.example]  
}

# Règle de pare-feu pour autoriser l'IP publique de la VM à accéder à MySQL
resource "azurerm_mysql_flexible_server_firewall_rule" "example" {
  name                = "allow-vm-access"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_flexible_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "40.68.225.200"  
}

resource "azurerm_network_security_group" "example" {
  name                = "tchak-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "allow-flask-port"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}


resource "azurerm_virtual_machine_extension" "example" {
  name                 = "custom-script"
  virtual_machine_id   = azurerm_linux_virtual_machine.example.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  {
    "script": "${filebase64("startup.sh")}"
  }
  SETTINGS
}



