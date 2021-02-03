output "docker_external_ip" {
  value = yandex_compute_instance.docker[*].network_interface.0.nat_ip_address
}

# generate inventory file for Ansible
resource "local_file" "inventory_generator" {
  content = templatefile("./generated_inventory.tpl",
    {
      dockerhost_names = yandex_compute_instance.docker[*].name,
      dockerhost_addrs = yandex_compute_instance.docker[*].network_interface.0.nat_ip_address

    }
  )
  filename = "../ansible/generated_inventory"
}
