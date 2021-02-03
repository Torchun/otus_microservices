# Torchun_microservices
Torchun microservices repository

# Lecture 16, homework 12
> Common tasks: play with Docker
##### Hint: use official installers for docker*

> Star: Make & deploy YC image with Terraform/Ansible/Packer
##### Hint:
```
docker-monolith/
├── db_config
├── docker-1.log
├── Dockerfile
├── infra
│   ├── ansible
│   │   ├── ansible.cfg
│   │   ├── generated_inventory
│   │   ├── inventory.py
│   │   └── playbooks
│   │       ├── install_docker.yml
│   │       └── run_reddit.yml
│   ├── packer
│   │   ├── docker.json
│   │   ├── variables.json
│   │   └── variables.json.example
│   └── terraform
│       ├── generated_inventory.tpl
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfstate
│       ├── terraform.tfstate.backup
│       ├── terraform.tfvars
│       ├── terraform.tfvars.example
│       └── variables.tf
├── mongod.conf
└── start.sh
```
### Step 1:
 - `mkdir -p docker-monolith/infra/terraform && cd $_`
 - `terraform init`
 - create Terraform files to create instance to play with while creating Ansible configs
 - Choose any suitable image_id: `yc compute image list --folder-id standard-images | grep -i ubuntu-1804-lts`
 - Make Terraform to put resulting IPs into suitable `generated_inventory` file:
At `main.tf`:
```
...
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
```
There is a need to use additional template `generated_inventory.tpl` with following content:
```
[docker]
%{ for i,name in dockerhost_names ~}
${dockerhost_names[i]} ansible_host=${dockerhost_addrs[i]}
%{ endfor ~}

```
##### Hint: That provides static inventory. For ansible task there is a need to modify your own dynamic inventory script!

### Step 2:
Now we have auto-created instance. Need to write Ansible configs. See files in repo.
 - cd to `docker-monolith/infra/ansible`
 - check files in repo
 - `ansible-playbook playbooks/install_docker.yml` and check instance
 - also check `ansible-playbook playbooks/run_reddit.yml`

### Step 3:
Create Packer's configs. See files in repo.
```
packer build -var-file=./packer/variables.json ./packer/docker.json
```
##### Hint: Packer's image ready. Need to modify Terraform's `main.tf` to use it and run Ansible's `run_reddit.yml`
Add provisioner to Terraform's `main.tf`:
```
...
  provisioner "local-exec" {
    command = "ansible-playbook playbooks/run_reddit.yml"
     working_dir = "../ansible"
  }
```
##### Hint: Don't forget to change `image_id` in `terraform.tfvars` to use freshly created Packer's image!
### Step 4: Final check
Go to Terraform directory and exec:
```
terraform destroy && terraform apply
```
Go to IP:9292 to check Reddit's page availability.
