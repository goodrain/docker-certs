#!/bin/bash
set -o errexit
SCRIPT_DIR=$(dirname $0)
CFSSL_VERSION=R1.2
DOWNLOAD_URL=https://pkg.cfssl.org
ARCH=linux-amd64
CFSSL_PKG=(cfssl  cfssl-bundle  cfssl-certinfo  cfssljson  cfssl-newkey  cfssl-scan  mkbundle  multirootca)
action=$1


function prepare() {
	for pkg in ${CFSSL_PKG[@]}
	do
		curl -L ${DOWNLOAD_URL}/${CFSSL_VERSION}/${pkg}_${ARCH} -o $PWD/bin/${pkg}
		chmod +x $PWD/bin/${pkg}
	done
}

function release() {
	docker build -t rainbond/cfssl:dev -f Dockerfile .
	docker push rainbond/cfssl:dev
}

case $action in
	prepare)
		prepare
	;;
    usage)
        echo "docker run --rm -v \$PWD/ssl:/ssl -w /ssl rainbond/cfssl:dev"
	;;
	*)
		[ ! -f "bin/cfssl" ] && prepare
		release
	;;
esac
