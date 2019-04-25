.PHONY:  build
build:
	@echo "build kubeconfig image"
	@docker build -t rainbond/kubecfg:dev .

.PHONY: ssl
ssl:
	@docker run --rm -v ${CURDIR}/ssl:/ssl -w /ssl rainbond/cfssl

.PHONY: run
run:
	@docker run -it --rm  -v ${CURDIR}/ssl:/etc/kubernetes/ssl -v ${CURDIR}/kubecfg:/k8s  rainbond/kubecfg 


.PHONY: debug
debug:
	@docker run -it rainbond/kubecfg bash

.PHONY: all
all: ssl run