
# Outputs
output "app_vnet_id" {
  value = module.app_network.vnet_id
}

output "db_vnet_id" {
  value = module.db_network.vnet_id
}

output "mgmt_vnet_id" {
  value = module.mgmt_network.vnet_id
}

output "app_subnet_ids" {
  value = module.app_network.subnet_ids
}

output "db_subnet_ids" {
  value = module.db_network.subnet_ids
}

output "mgmt_subnet_ids" {
  value = module.mgmt_network.subnet_ids
}

output "app_nsg_ids" {
  value = module.app_network.nsg_ids
}

output "db_nsg_ids" {
  value = module.db_network.nsg_ids
}

output "mgmt_nsg_ids" {
  value = module.mgmt_network.nsg_ids
}