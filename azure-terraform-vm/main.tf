terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstate258223046"
    container_name       = "tfstate"
    key                  = "azure-terraform-vm.tfstate"
    use_azuread_auth     = true
  }

}
provider "azurerm" {
  features {
     resource_group {
       prevent_deletion_if_contains_resources = false
  }
}
  }


# -------------------------
# Virtual Network
# -------------------------

resource "azurerm_virtual_network" "lab" {
  name                = "vnet-terraform-lab"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}

# -------------------------
# Subnet
# -------------------------

resource "azurerm_subnet" "lab" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.10.1.0/24"]
}

# -------------------------
# Network Security Group
# -------------------------
resource "azurerm_network_security_group" "lab" {
  name                = "nsg-terraform-vm"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name                   = "Allow-SSH"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "22"

    # CHANGE THIS TO YOUR PUBLIC IP
    source_address_prefix = "102.88.167.64/32"

    destination_address_prefix = "*"
  }
}

# -------------------------
# Public IP
# -------------------------

resource "azurerm_public_ip" "lab" {
  name                = "pip-terraform-vm"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  allocation_method = "Static"
  sku               = "Standard"
}

# -------------------------
# Network Interface
# -------------------------

resource "azurerm_network_interface" "lab" {
  name                = "nic-terraform-vm"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab.id
  }
}

# -------------------------
# Associate NSG with NIC
# -------------------------

resource "azurerm_network_interface_security_group_association" "lab" {
  network_interface_id      = azurerm_network_interface.lab.id
  network_security_group_id = azurerm_network_security_group.lab.id
}

variable "ssh_public_key" {
  description = "SSH public key for the Azure VM"
  type        = string
}

# -------------------------
# Linux VM
# -------------------------

resource "azurerm_linux_virtual_machine" "lab" {
  name                = "testVM1"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location

  size           = "Standard_D2nlds_v6"
  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.lab.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}





# -------------------------
# Outputs
# -------------------------
output "public_ip" {
  value = azurerm_public_ip.lab.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.lab.private_ip_address
}