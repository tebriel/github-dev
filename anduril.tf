locals {
  gpu_location = "southcentralus"
}

resource "azurerm_public_ip" "anduril" {
  name                = "anduril-ip"
  location            = local.gpu_location
  resource_group_name = azurerm_resource_group.github-dev.name
  allocation_method   = "Static"
}

resource "azurerm_virtual_network" "anduril-dev-vnet" {
  name                = "anduril-dev-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = local.gpu_location
  resource_group_name = azurerm_resource_group.github-dev.name
}

resource "azurerm_subnet" "anduril" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.github-dev.name
  virtual_network_name = azurerm_virtual_network.anduril-dev-vnet.name
  address_prefixes = [
    "10.0.2.0/24",
  ]
}

resource "azurerm_dns_a_record" "anduril" {
  name                = "anduril"
  zone_name           = data.azurerm_dns_zone.dev.name
  resource_group_name = azurerm_resource_group.github-dev.name
  ttl                 = 60
  target_resource_id  = azurerm_public_ip.anduril.id
}

resource "azurerm_network_interface" "anduril" {
  name                = "anduril-nic"
  location            = local.gpu_location
  resource_group_name = azurerm_resource_group.github-dev.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.anduril.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.anduril.id
  }
}

resource "azurerm_network_security_group" "anduril" {
  name                = "anduril-sg"
  location            = local.gpu_location
  resource_group_name = azurerm_resource_group.github-dev.name

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "anduril" {
  network_interface_id      = azurerm_network_interface.anduril.id
  network_security_group_id = azurerm_network_security_group.anduril.id
}

resource "azurerm_network_security_rule" "anduril-rdp" {
  name                       = "anduril-RDP"
  priority                   = 300
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "3389"
  source_address_prefix      = var.home_ip
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.github-dev.name
  network_security_group_name = azurerm_network_security_group.anduril.name
}

resource "azurerm_network_security_rule" "anduril-steam-udp" {
  name              = "anduril-steam-udp"
  priority          = 400
  direction         = "Inbound"
  access            = "Allow"
  protocol          = "Udp"
  source_port_range = "*"
  destination_port_ranges = [
    "27031",
    "27036",
  ]
  source_address_prefix      = var.home_ip
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.github-dev.name
  network_security_group_name = azurerm_network_security_group.anduril.name
}

resource "azurerm_network_security_rule" "anduril-steam-tcp" {
  name                       = "anduril-steam-tcp"
  priority                   = 500
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "27036-27037"
  source_address_prefix      = var.home_ip
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.github-dev.name
  network_security_group_name = azurerm_network_security_group.anduril.name
}

resource "azurerm_windows_virtual_machine" "anduril" {
  name                     = "anduril"
  resource_group_name      = azurerm_resource_group.github-dev.name
  location                 = local.gpu_location
  size                     = "Standard_NV6"
  admin_username           = var.admin_username
  admin_password           = var.admin_password
  license_type             = "Windows_Client"
  enable_automatic_updates = true
  provision_vm_agent       = true

  network_interface_ids = [
    azurerm_network_interface.anduril.id,
  ]

  os_disk {
    caching              = "None"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "nvidia" {
  name                       = "NvidiaGpuDriverWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.anduril.id
  publisher                  = "Microsoft.HpcCompute"
  type                       = "NvidiaGpuDriverWindows"
  type_handler_version       = "1.2"
  auto_upgrade_minor_version = true

  settings = "{}"

  lifecycle {
    ignore_changes = [
      settings,
    ]
  }
}
