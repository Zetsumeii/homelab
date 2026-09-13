module "vm_test" {
  source = "./modules/debian"

  vm_name        = "test-01"
  vm_id          = 200
  node_name      = var.node_name
  template_id    = var.template_id
  storage_pool   = var.storage_pool
  gateway        = var.gateway
  ssh_public_key = var.ssh_public_key
  ip_address     = "192.168.1.60/24"
}
