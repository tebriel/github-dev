resource "azurerm_virtual_network" "github-dev-vnet" {
  count               = var.rivendell_enable
  name                = "github-dev-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.github-dev.location
  resource_group_name = azurerm_resource_group.github-dev.name
}

resource "azurerm_subnet" "default" {
  count                = var.rivendell_enable
  name                 = "default"
  resource_group_name  = azurerm_resource_group.github-dev.name
  virtual_network_name = azurerm_virtual_network.github-dev-vnet[count.index].name
  address_prefixes = [
    "10.0.2.0/24",
  ]
}

resource "azurerm_public_ip" "rivendell" {
  count               = var.rivendell_enable
  name                = "rivendell-ip"
  location            = azurerm_resource_group.github-dev.location
  resource_group_name = azurerm_resource_group.github-dev.name
  allocation_method   = "Static"
}

data "azurerm_dns_zone" "dev" {
  name                = "dev.frodux.in"
  resource_group_name = azurerm_resource_group.github-dev.name
}

resource "azurerm_dns_a_record" "rivendell" {
  count               = var.rivendell_enable
  name                = "rivendell"
  zone_name           = data.azurerm_dns_zone.dev.name
  resource_group_name = azurerm_resource_group.github-dev.name
  ttl                 = 60
  target_resource_id  = azurerm_public_ip.rivendell[count.index].id
}

resource "azurerm_network_security_group" "rivendell" {
  count               = var.rivendell_enable
  name                = "rivendell-sg"
  location            = azurerm_resource_group.github-dev.location
  resource_group_name = azurerm_resource_group.github-dev.name

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "rivendell" {
  count                     = var.rivendell_enable
  network_interface_id      = azurerm_network_interface.rivendell[count.index].id
  network_security_group_id = azurerm_network_security_group.rivendell[count.index].id
}

resource "azurerm_network_security_rule" "rivendell-rdp" {
  count                      = var.rivendell_enable
  name                       = "rivendell-RDP"
  priority                   = 350
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "3389"
  source_address_prefix      = var.home_ip
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.github-dev.name
  network_security_group_name = azurerm_network_security_group.rivendell[count.index].name
}

resource "azurerm_network_interface" "rivendell" {
  count               = var.rivendell_enable
  name                = "rivendell-nic"
  location            = azurerm_resource_group.github-dev.location
  resource_group_name = azurerm_resource_group.github-dev.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.default[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.rivendell[count.index].id
  }
}

resource "azurerm_dev_test_lab" "github-dev" {
  count               = var.rivendell_enable
  name                = "GithubDevLab"
  location            = azurerm_resource_group.github-dev.location
  resource_group_name = azurerm_resource_group.github-dev.name
}

resource "azurerm_windows_virtual_machine" "rivendell" {
  count                    = var.rivendell_enable
  name                     = "rivendell"
  resource_group_name      = azurerm_resource_group.github-dev.name
  location                 = azurerm_resource_group.github-dev.location
  size                     = "Standard_D2S_v3"
  admin_username           = var.admin_username
  admin_password           = var.admin_password
  license_type             = "Windows_Client"
  enable_automatic_updates = true
  provision_vm_agent       = true

  network_interface_ids = [
    azurerm_network_interface.rivendell[count.index].id,
  ]

  os_disk {
    caching              = "None"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "rs5-pro-g2"
    version   = "latest"
  }
}
