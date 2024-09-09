# provider

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.128.0"
    }
  }
}

locals {
  cloud_id = "b1g4d2lqr55m6omsfmgq"
  folder_id = "b1gvodeboed445k4obcd"
  sa_key_path = "C:\\Users\\user\\Desktop\\travelline\\balancer\\authorized_key.json"
  meta_file = "${file("C:\\Users\\user\\Desktop\\travelline\\balancer\\terraform\\meta.txt")}"
  ssh_key = "user:${file("C:\\Users\\user\\.ssh\\id_ed25519.pub")}"
  centos_id = "fd837b0gcg6klm9d9nl6"
}

provider "yandex" {
  cloud_id = local.cloud_id
  folder_id = local.folder_id
  service_account_key_file = local.sa_key_path
  zone = "ru-central1-a"
}

# network

resource "yandex_vpc_network" "network" {
  name = "network"
}

resource "yandex_vpc_subnet" "sub-net" {
  name = "sub-net"
  zone = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id = yandex_vpc_network.network.id
  route_table_id = yandex_vpc_route_table.route-table.id
}

resource "yandex_vpc_gateway" "nat-gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route-table" {
  name = "route-table"
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id = yandex_vpc_gateway.nat-gateway.id
  }
}

# VMs

resource "yandex_compute_instance" "balancer-vm" {
  name = "balancer-vm"
  allow_stopping_for_update = true

  resources {
    core_fraction = 5
    cores = 2
    memory = 1
  }

  boot_disk {
    initialize_params {
      image_id = local.centos_id
      type = "network-hdd"
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.sub-net.id
    ip_address = "192.168.10.10"
    nat = true
  }

  metadata = {
    user-data = local.meta_file
    ssh-keys = local.ssh_key
  }
}

resource "yandex_compute_instance" "backend-vm-1" {
  name = "backend-vm-1"
  allow_stopping_for_update = true

  resources {
    core_fraction = 5
    cores = 2
    memory = 1
  }

  boot_disk {
    initialize_params {
      image_id = local.centos_id
      type = "network-hdd"
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.sub-net.id
    ip_address = "192.168.10.11"
    nat = true
  }

  hostname = "backend-1"

  metadata = {
    user-data = local.meta_file
    ssh-keys = local.ssh_key
  }
}

resource "yandex_compute_instance" "backend-vm-2" {
  name = "backend-vm-2"
  allow_stopping_for_update = true

  resources {
    core_fraction = 5
    cores = 2
    memory = 1
  }

  boot_disk {
    initialize_params {
      image_id = local.centos_id
      type = "network-hdd"
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.sub-net.id
    ip_address = "192.168.10.12"
  }

  hostname = "backend-2"

  metadata = {
    user-data = local.meta_file
    ssh-keys = local.ssh_key
  }
}


output "external_ip_balancer" {
  value = yandex_compute_instance.balancer-vm.network_interface.0.nat_ip_address
}