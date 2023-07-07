.PHONY: all build-all build help install_kind install_kubectl \
	create_kind_cluster create_docker_registry connect_registry_to_kind_network \
	connect_registry_to_kind create_kind_cluster_with_registry delete_kind_cluster \
	delete_docker_registry  build_docker_image \
	install_nginx_ingress clean_up 

APP_NAME:=fastapi-example
VERSION:=0.0.1
REGISTRY=127.0.0.1:5000
IMAGE=${REGISTRY}/${APP_NAME}
TAG_ALIAS=latest


# Dependencies

install_nginx_ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml && \
	  kubectl wait --namespace ingress-nginx \
  		--for=condition=ready pod \
  		--selector=app.kubernetes.io/component=controller \
  		--timeout=120s || true

# Create cluster
create_docker_registry:
	if docker ps | grep -q 'local-registry'; \
	then echo "---> local-registry already created; skipping"; \
	else docker run --name local-registry -d --restart=always -p 5000:5000 registry:2; \
	fi

create_kind_cluster: create_docker_registry
	kind create cluster --name fastapi --config kind_config.yml || true && \
	  kubectl get nodes

connect_registry_to_kind_network:
	docker network connect kind local-registry || true

connect_registry_to_kind: connect_registry_to_kind_network
	kubectl apply -f kind_configmap.yml

create_kind_cluster_with_registry:
	$(MAKE) create_kind_cluster && $(MAKE) connect_registry_to_kind

up: create_kind_cluster_with_registry 
	$(MAKE) install_nginx_ingress 


# Clean up
delete_docker_registry: 
	docker stop local-registry && docker rm local-registry

delete_kind_cluster: delete_docker_registry
	kind delete cluster --name fastapi

clean:
	$(MAKE) delete_kind_cluster


all: up build-all

build-all: build tag-alias push

build: 
	$(info Building ${IMAGE}:${VERSION} ...)
	docker build --pull -t "${APP_NAME}:${VERSION}" .

tag-alias:
	docker tag ${APP_NAME}:${VERSION} ${APP_NAME}:${TAG_ALIAS}
	docker tag ${APP_NAME}:${VERSION} ${IMAGE}:${VERSION}
	docker tag ${IMAGE}:${VERSION} ${IMAGE}:${TAG_ALIAS}

push:
	docker push -a ${IMAGE}


#Helm install name
export HELM_NAME=${APP_NAME}
export USE_IMAGE=${IMAGE}
HELM_CHART_PATH = ./charts

# List of helm targets
HELM_TARGETS = all install install-dry upgrade upgrade-all upgrade-dry dep-build dep-update uninstall
# Add all helm targets with the "helm-" prefix.
HELM_TARGETS_PREFIX = $(addprefix helm-, $(HELM_TARGETS))
$(HELM_TARGETS_PREFIX):
	$(MAKE) -C $(HELM_CHART_PATH) $(subst helm-,,$@)

help:
	@echo '*** Usage of this file:'
	@echo 'make up          : Setup local dev environment (k8s cluster and registry) using kind'
	@echo 'make clean      : Teardown local dev environment'
	@echo 'make build-all : Build and push the images to the local registry'
	@echo 'make build     : Build the image without pushing'
	@echo 'make tag-alias : Make a tag alias'
	@echo 'make push      : Push the images to the local registry'
	@echo
	@echo '*** Some helm related commands:'
	@echo 'make helm-all         : Install helm chart including updating and building dependencies'
	@echo 'make helm-install     : Install helm chart in the current kubectl context'
	@echo 'make helm-install-dry : Do a simulation of an installation'
	@echo 'make helm-upgrade     : Upgrade the helm chart as is'
	@echo 'make helm-upgrade-all : Upgrade the helm chart including updating and building dependencies'
	@echo 'make helm-upgrade-dry : Do a simulation of an upgrade'
	@echo 'make helm-dep-build   : Build the chart dependencies from the Chart.lock file values.yaml is not evaluated'
	@echo 'make helm-dep-update  : Refresh the and download the dependencies from the Chart.yaml file'
	@echo 'make helm-uninstall   : Uninstall the helm release'

