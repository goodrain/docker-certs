#!/bin/bash

set -x

function create_ca() {
	cfssl gencert -initca /etc/cfssl/ca-csr.json | cfssljson -bare ca
}
function create_k8s_csr() {
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=/etc/cfssl/ca-config.json -profile=kubernetes /etc/cfssl/kubernetes-csr.json | cfssljson -bare kubernetes
}

function create_admin_csr() {
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=/etc/cfssl/ca-config.json -profile=kubernetes /etc/cfssl/admin-csr.json | cfssljson -bare admin
}

function create_kubelet_csr() {
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=/etc/cfssl/ca-config.json -profile=kubernetes /etc/cfssl/kubelet-csr.json | cfssljson -bare kubelet
}

function create_proxy_csr() {
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=/etc/cfssl/ca-config.json -profile=kubernetes /etc/cfssl/kube-proxy-csr.json | cfssljson -bare kube-proxy
}

function create_k8s_new_csr() {
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=/etc/cfssl/ca-config.json -profile=kubernetes /etc/cfssl/k8s-csr-new.json | cfssljson -bare kubernetes
}

if [ "$1" = "bash" ];then
	exec /bin/bash
elif [ "$1" = "kip" ];then
        ip_list=${@:2}
        for ip in ${ip_list[@]};do
        sed -i "/\"127.0.0.1\",/a\""$ip"\"," /etc/cfssl/k8s-csr-new.json
        done

		cat /etc/cfssl/k8s-csr-new.json

        create_ca
        create_k8s_new_csr
        create_admin_csr
    	create_kubelet_csr
        create_proxy_csr
else
	create_ca
	create_k8s_csr
	create_admin_csr
    create_kubelet_csr
	create_proxy_csr
fi