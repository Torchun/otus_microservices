### Borrowed from and inspired by https://github.com/Otus-DevOps-2020-11/iudanet_microservices/blob/main/Makefile
#Envs
USER_NAME=torchun
DOCKER_TAG=latest

# Docker builds
build:: build-prometheus build-ui build-comment build-post build-mongodb-exporter build-blackbox-exporter

build-prometheus::
	cd monitoring/prometheus && \
	docker build -t $(USER_NAME)/prometheus:$(DOCKER_TAG) .
build-ui::
	cd src/ui && \
	USER_NAME=$(USER_NAME) bash docker_build.sh
build-comment::
	cd src/comment && \
	USER_NAME=$(USER_NAME) bash docker_build.sh
build-post::
	cd src/post-py && \
	USER_NAME=$(USER_NAME) bash docker_build.sh
build-mongodb-exporter::
	cd monitoring/exporters/mongodb && \
	docker build -t $(USER_NAME)/mongodb_exporter:$(DOCKER_TAG) .
build-blackbox-exporter::
	cd monitoring/exporters/blackbox && \
	docker build -t $(USER_NAME)/blackbox_exporter:$(DOCKER_TAG) .

#Docker Push
push:: push-prometheus push-ui push-comment push-post push-mongodb-exporter push-blackbox-exporter

push-prometheus:: build-prometheus docker-login
	docker push $(USER_NAME)/prometheus:$(DOCKER_TAG)
push-ui:: build-ui docker-login
	docker push $(USER_NAME)/ui:$(DOCKER_TAG)
push-comment:: build-comment docker-login
	docker push $(USER_NAME)/comment:$(DOCKER_TAG)
push-post:: build-post docker-login
	docker push $(USER_NAME)/post:$(DOCKER_TAG)
push-mongodb-exporter:: build-mongodb-exporter docker-login
	docker push $(USER_NAME)/exporters/mongodb:$(DOCKER_TAG)
push-blackbox-exporter:: build-blackbox-exporter docker-login
	docker push $(USER_NAME)/exporters/blackbox:$(DOCKER_TAG)

# Docker Login
docker-login::
	docker login -u $(USER_NAME)

up:: build docker-compose-up

docker-compose-up::
	cd docker && \
	docker-compose up -d

docker-compose-ps::
	cd docker && \
	docker-compose ps

clean:: docker-compose-down

docker-compose-down::
	cd docker && \
	docker-compose down -v
