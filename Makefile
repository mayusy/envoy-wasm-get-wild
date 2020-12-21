WASM_NAME=webassemblyhub.io/mayusy/getwild
TAG=dev
ID=getwild
NAME=getwild

login:
	wasme login -u $(USER) -p $(PASSWORD)

build:
	wasme build tinygo -t $(WASM_NAME):$(TAG) ./

push:
	wasme push $(WASM_NAME):$(TAG)

deploy:
	wasme deploy istio $(WASM_NAME):$(TAG) --id=$(ID) ./
	kubectl wait -n default --for=condition=ready pod -l app=productpage --timeout=600s

undeploy:
	wasme undeploy istio $(WASM_NAME):$(TAG) --id=$(ID) ./

kind/start:
	kind create cluster --name $(NAME)

kind/login:
	kubectl cluster-info --context kind-$(NAME)

kind/stop:
	kind delete cluster --name $(NAME)

kind/restart: \
	kind/stop \
	kind/start

istio/install:
	istioctl install --set profile=demo
	kubectl label namespace default istio-injection=enabled
	kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml

refresh: \
	kind/restart \
	istio/install \
	build \
	push
	kubectl wait -n default --for=condition=ready pod -l app=productpage --timeout=600s
	@make deploy


