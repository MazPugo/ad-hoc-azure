provider "azurerm" {
  features {}
  subscription_id = "my_subscription"
}

resource "azurerm_resource_group" "rg" {
  name     = "ad-hoc-demo-rg"
  location = "UK South"
}

#NSG allowing SSH
resource "azurerm_network_security_group" "nsg" {
  name                = "ad-hoc-demo-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

#Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "ad-hoc-demo-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "ad-hoc-demo-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#Associate NSG to subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Public IPs
resource "azurerm_public_ip" "pip" {
  count               = 4
  name                = "ad-hoc-demo-pip-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

#Network Interfaces
resource "azurerm_network_interface" "nic" {
  count               = 4
  name                = "ad-hoc-demo-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

#Linux Virtual Machines
resource "azurerm_virtual_machine" "vm" {
  count                 = 4
  name                  = "ad-hoc-demo-vm-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "ad-hoc-demo-osdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts"
  version   = "latest"
}

  os_profile {
    computer_name  = "ad-hoc-demo-vm-${count.index}"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_ed25519.pub")
    }
  }
}

#Output Public IPs
output "public_ips" {
  value = azurerm_public_ip.pip[*].ip_address
}
