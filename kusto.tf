resource "azurerm_kusto_cluster" "test" {
  count                     = var.kusto_enable
  name                      = "tebrielkustotest${count.index}"
  location                  = azurerm_resource_group.github-dev.location
  resource_group_name       = azurerm_resource_group.github-dev.name
  engine                    = "V3"
  double_encryption_enabled = false
  enable_disk_encryption    = false
  enable_purge              = false
  enable_streaming_ingest   = false
  zones                     = ["1"]
  trusted_external_tenants  = ["*"]
  language_extensions       = []

  sku {
    name     = "Dev(No SLA)_Standard_E2a_v4"
    capacity = 1
  }

  tags = {}
}

resource "azurerm_kusto_database" "test" {
  count               = var.kusto_enable
  name                = "tebrielkustotest${count.index}"
  resource_group_name = azurerm_resource_group.github-dev.name
  location            = azurerm_resource_group.github-dev.location
  cluster_name        = azurerm_kusto_cluster.test[count.index].name
}
