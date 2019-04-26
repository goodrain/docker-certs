#!/bin/bash

get::grcert(){
    mkdir ./tmp
    pushd ./tmp
        docker run --rm -v $PWD/tools:/sysdir rainbond/cni:rbd_v5.1.3-release tar zxf /pkg.tgz -C /sysdir
    popd
    cp -a ./tmp/tools/bin/grcert dist/grcert
    rm -rf ./tmp
    chmod +x dist/grcert
}

get::cfssl(){
    ARCH=linux-amd64
    CFSSL_PKG=(cfssl cfssl-certinfo cfssljson)
	for pkg in ${CFSSL_PKG[@]}
	do
        [ -f "dist/${pkg}" ] && rm -rf dist/${pkg}
		curl -s -L https://pkg.cfssl.org/R1.2/${pkg}_${ARCH} -o dist/${pkg}
		chmod +x dist/${pkg}
	done
}

get::k8s(){
    [ -f "dist/kubectl" ] && rm -rf dist/kubectl
    curl -s -L https://storage.googleapis.com/kubernetes-release/release/v1.10.13/bin/linux/amd64/kubectl -o dist/kubectl
    chmod +x dist/kubectl
}

get(){
    echo "Download tool binaries"
    [ -d "dist" ] && rm -rf dist
    mkdir dist
    get::grcert
    get::cfssl
    get::k8s
}

release(){
    echo "build docker images"
    docker build -t rainbond/r6dctl:docker-cfg-certs .
    if [ ! -z "$PROD_RELEASE" ]; then
        docker push rainbond/r6dctl:docker-cfg-certs
    fi
}

case $1 in
    *)
        get
        release
    ;;
esac