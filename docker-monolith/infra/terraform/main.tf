provider "yandex" {
  version                  = "~> 0.35.0"
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_compute_instance" "docker" {
  count = var.instance_count
  name  = "docker-${count.index}"

  resources {
    cores  = 2
    core_fraction = 5
    memory = 2
  }
  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
