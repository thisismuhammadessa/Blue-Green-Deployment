output "cluster_id" {
  value = azurerm_kubernetes_cluster.devopsshack.id
}

output "node_pool_name" {
  value = azurerm_kubernetes_cluster.devopsshack.default_node_pool[0].name
}

output "vnet_id" {
  value = azurerm_virtual_network.devopsshack_vnet.id
}

output "subnet_ids" {
  value = [
    azurerm_subnet.devopsshack_subnet_1.id,
    azurerm_subnet.devopsshack_subnet_2.id
  ]
}

