# Torchun_microservices
Torchun microservices repository

# Lecture 23, homework 17
## Common tasks:
 - reorganize `docker-compose.yml`, extract monitoring to `docker-compose-monitoring.yml`
 - cAdvisor
 - Grafana: sources, dashboards
 - Alertmanager -> Slack notifications
##### Solution: as described in PDF

## Starred tasks:
 - Append Makefile to include build/push/deploy for grafana and alertmanager
 - Docker Engine stats straightforward to Prometheus (without cAdvicer)
 - Additional panel in Grafana with 95 percentile
 - Grafana dynamic inventory using pre-created dashboards (downloaded or self-deigned)
##### Solution: See corresponding commits and files
##### Useful commands:
```
docker-compose --env-file ./.env -f docker-compose.yml up -d
docker-compose ps -a
```
##### Useful tips:
```
export USER_NAME=your_user_name
docker build -t $USER_NAME/prometheus .

docker-compose -f docker-compose-monitoring.yml down
docker-compose -f docker-compose-monitoring.yml up -d

docker build -t $USER_NAME/alertmanager .
```

 - To enable docker native metrics to be exposed, add to /etc/docker/daemon.json:
```
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}
```
- Restart Docker engine (will stop all containers):
```
sudo systemctl daemon-reload
sudo systemctl restart docker
```

 - [Dynamic provisioning for Grafana:](https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards)

 - ##### After export dashboard to JSON, need manually to fix "datasource": "${DS_PROMETHEUS_SERVER}" / "${DS_PROMETHEUS}" to string "Prometheus" (simple string, not variable)
```
docker build -t $USER_NAME/grafana .
docker push $USER_NAME/grafana
```

# Lecture 22, homework 16
## Common tasks:
 - reorganize directores
 - add Prometheus monitoring for UI, Comment, Post containers
 - add node_exporter
##### Solution: as described in PDF

## Starred tasks:
 - add mongodb_exporter
 - add [blackbox_exporter](https://github.com/prometheus/blackbox_exporter#prometheus-configuration)
 - create Makefile to build / push / docker-compose commands
##### Solution: See corresponding commits and files
##### Useful comands:
```
docker-compose --env-file ./.env -f docker-compose.yml up -d
docker-compose ps -a
```
##### Useful tips:

To monitor smth:
1. Create image:
```
docker build -t $USER_NAME/mongodb_exporter:0.20.2 .
docker push $USER_NAME/mongodb_exporter:0.20.2
```
2. Add monitoring to prometheus.yml, rebuild image as config ADDed via Dockerfile and push to registry
3. Start image, e.g. via docker-compose.yml

Links to DockerHub images:
 - [https://hub.docker.com/repository/docker/torchun/prometheus](https://hub.docker.com/repository/docker/torchun/prometheus)
 - [https://hub.docker.com/repository/docker/torchun/post](https://hub.docker.com/repository/docker/torchun/post)
 - [https://hub.docker.com/repository/docker/torchun/comment](https://hub.docker.com/repository/docker/torchun/comment)
 - [https://hub.docker.com/repository/docker/torchun/ui](https://hub.docker.com/repository/docker/torchun/ui)
 - [https://hub.docker.com/repository/docker/torchun/mongodb_exporter](https://hub.docker.com/repository/docker/torchun/mongodb_exporter)
 - [https://hub.docker.com/repository/docker/torchun/blackbox_exporter](https://hub.docker.com/repository/docker/torchun/blackbox_exporter)


# Lecture 18, homework 14
> Common tasks: Playing with docker networks

As described in PDF.
##### Hint: use following commands:
```
docker-machine ls
eval $(docker-machine env docker-host)
docker kill $(docker ps -q)

docker network create back_net --subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24

docker run -d --network=front_net -p 9292:9292 --name ui torchun/ui:1.0
docker run -d --network=back_net --name comment torchun/comment:1.0
docker run -d --network=back_net --name post torchun/post:1.0
docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db mongo:latest

docker network connect front_net post
docker network connect front_net comment
```
Docker compose commands:
```
export USERNAME=torchun
docker-compose up -d
docker-compose ps
```

> Common tasks: .env, versions and variables to docker-compose

 - Place in `.env` file desired variables:
```
USERNAME=torchun
PORT=9292
VERSION=1.0
```
 - Refactor "version" from static to var and specify networks for each service:
```
version: '3.3'
services:
  post_db:
    image: mongo:3.2
    volumes:
      - post_db:/data/db
    networks:
      - back_net
  ui:
    build: ./ui
    image: ${USERNAME}/ui:${VERSION}
    ports:
      - ${PORT}:${PORT}/tcp
    networks:
      - front_net
  post:
    build: ./post-py
    image: ${USERNAME}/post:${VERSION}
    networks:
      - front_net
      - back_net
  comment:
    build: ./comment
    image: ${USERNAME}/comment:${VERSION}
    networks:
      - front_net
      - back_net

volumes:
  post_db:

networks:
  front_net:
  back_net:
```
Now rebuild to ckeck:
 - `docker-compose kill`
 - `docker-compose up -d`
 - `docker-compose ps`

> Specifying project name in docker compose

As easy as `docker-compose -p project_name up -d`

> Star: work with docker-compose.override.yml
##### Modify App's code without restart of container with `docker-compose.override.yml` changes:
```
services:
  post:
    volumes:
    - app_volume:/app
```
##### Start Puma in debug mode with 2 workers with `docker-compose.override.yml`:
```
  ui:
    command: puma --debug -w 2
  comment:
    command: puma --debug -w 2
```
Check with firing commands:
```
docker-compose kill
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d
```
```
docker-compose ps
    Name                  Command             State           Ports
----------------------------------------------------------------------------
src_comment_1   puma --debug -w 2             Up
src_post_1      python3 post_app.py           Up
src_post_db_1   docker-entrypoint.sh mongod   Up      27017/tcp
src_ui_1        puma --debug -w 2             Up      0.0.0.0:9292->9292/tcp

```


# Lecture 17, homework 13
> Common tasks: build default images

As described in PDF

> Star:  re-run containers with new network aliases and pass vars

Stop all containers:
 - ` docker kill $(docker ps -q)`

Re-run containers with new params (same `reddit` network in use):
```
docker run -d \
    --network=reddit \
    --network-alias=post_db_1 \
    --network-alias=comment_db_1 \
    mongo:latest

docker run -d \
    --network=reddit \
    -e POST_SERVICE_HOST=post_1 \
    -e COMMENT_SERVICE_HOST=comment_1 \
    -p 9292:9292 \
    torchun/ui:1.0

docker run -d \
    --network=reddit \
    -e COMMENT_DATABASE_HOST=comment_db_1 \
    -e COMMENT_DATABASE=comments_1 \
    --network-alias=comment_1 \
    torchun/comment:1.0

docker run -d \
    --network=reddit \
    -e POST_DATABASE_HOST=post_db_1 \
    -e POST_DATABASE=posts_1 \
    --network-alias=post_1 \
    torchun/post:1.0
```
> Star: re-build image based on Alpine
 - `cp ui/Dockerfile ui/Dockerfile.1`
 - in `ui/Dockerfile.1` make changes:
```
# FROM ubuntu:16.04
# RUN apt-get update \
#     && apt-get install -y ruby-full ruby-dev build-essential \
#     && gem install bundler --no-ri --no-rdoc

FROM alpine:3.6
RUN apk update --no-cache \
    && apk add --no-cache ruby ruby-dev ruby-bundler build-base \
    && gem install bundler --no-rdoc --no-ri \
    && rm -rf /var/cache/apk/*
```
 - `docker build -t torchun/ui:3.0 ./ui -f ui/Dockerfile.1`
 - Compare sizes:
```
$ docker images
REPOSITORY        TAG            IMAGE ID       CREATED          SIZE
torchun/ui        3.0            456c9d70a8f7   32 seconds ago   205MB
torchun/ui        2.0            276f389172e5   18 minutes ago   458MB
torchun/ui        1.0            5c703f9f144d   32 minutes ago   770MB
...

```
Don't forget to remove `Exited` containers as they are not needed anymore:
```
docker rm `docker ps -a | grep Exited | awk '{print $1}'`
```


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
