#!/bin/bash

set -e

ACTION=$1

MIP=$2
IPS=${@:2}

[ -z "$MIP" ] && echo "eg: docker run -it --rm rainbond/r6dctl:docker-cfg-certs kip 192.168.1.1" && exit 1

KUBE_APISERVER="https://kubeapi.goodrain.me:6443"
CA_PATH="/opt/rainbond/etc/rbd-api/region.goodrain.me/ssl"
K8S_SSL="/opt/rainbond/etc/kubernetes/ssl"
K8S_CFG="/opt/rainbond/etc/kubernetes/kubecfg"

if [ ! -z $API  ];then
    KUBE_APISERVER=$API
fi

[ -d "$CA_PATH" ] || mkdir -p $CA_PATH
[ -d "$K8S_SSL" ] || mkdir -p $K8S_SSL
[ -d "$K8S_CFG" ] || mkdir -p $K8S_CFG
[ -d "/grdata/kubernetes" ] || mkdir -p /grdata/kubernetes

export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')

generate_ssl(){
    pushd $K8S_SSL
    cfssl gencert -initca /etc/cfssl/ca-csr.json | cfssljson -bare ca
    if [ "$ACTION" == "kip" ];then
        for ip in ${IPS[@]};do
        sed -i "/\"127.0.0.1\",/a\""$ip"\"," /etc/cfssl/k8s-csr-new.json
        done
        cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=/etc/cfssl/ca-config.json -profile=kubernetes /etc/cfssl/k8s-csr-new.json | cfssljson -bare kubernetes
    else
	    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=/etc/cfssl/ca-config.json -profile=kubernetes /etc/cfssl/kubernetes-csr.json | cfssljson -bare kubernetes
    fi
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=/etc/cfssl/ca-config.json -profile=kubernetes /etc/cfssl/admin-csr.json | cfssljson -bare admin
    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=/etc/cfssl/ca-config.json -profile=kubernetes /etc/cfssl/kubelet-csr.json | cfssljson -bare kubelet
    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=/etc/cfssl/ca-config.json -profile=kubernetes /etc/cfssl/kube-proxy-csr.json | cfssljson -bare kube-proxy
    popd
}

generate_k8s(){    
    pushd $K8S_CFG
    cat > token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

      kubectl config set-cluster kubernetes \
        --certificate-authority=${K8S_SSL}/ca.pem \
        --embed-certs=true \
        --server=${KUBE_APISERVER} \
        --kubeconfig=bootstrap.kubeconfig

      kubectl config set-credentials kubelet-bootstrap \
        --token=${BOOTSTRAP_TOKEN} \
        --kubeconfig=bootstrap.kubeconfig

      kubectl config set-context default \
        --cluster=kubernetes \
        --user=kubelet-bootstrap \
        --kubeconfig=bootstrap.kubeconfig

      kubectl config use-context default --kubeconfig=bootstrap.kubeconfig

      kubectl config set-cluster kubernetes \
        --certificate-authority=${K8S_SSL}/ca.pem \
        --embed-certs=true \
        --server=${KUBE_APISERVER} \
        --kubeconfig=kube-proxy.kubeconfig

      kubectl config set-credentials kube-proxy \
        --client-certificate=${K8S_SSL}/kube-proxy.pem \
        --client-key=${K8S_SSL}/kube-proxy-key.pem \
        --embed-certs=true \
        --kubeconfig=kube-proxy.kubeconfig

      kubectl config set-context default \
        --cluster=kubernetes \
        --user=kube-proxy \
        --kubeconfig=kube-proxy.kubeconfig

      kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

            kubectl config set-cluster kubernetes \
        --certificate-authority=${K8S_SSL}/ca.pem \
        --embed-certs=true \
        --server=${KUBE_APISERVER} \
        --kubeconfig=admin.kubeconfig

      kubectl config set-credentials admin \
        --client-certificate=${K8S_SSL}/admin.pem \
        --client-key=${K8S_SSL}/admin-key.pem \
        --embed-certs=true \
        --kubeconfig=admin.kubeconfig

      kubectl config set-context default \
        --cluster=kubernetes \
        --user=admin \
        --kubeconfig=admin.kubeconfig

      kubectl config use-context default --kubeconfig=admin.kubeconfig

            kubectl config set-cluster kubernetes \
        --certificate-authority=${K8S_SSL}/ca.pem \
        --embed-certs=true \
        --server=${KUBE_APISERVER} \
        --kubeconfig=kubelet.kubeconfig

      kubectl config set-credentials node \
        --client-certificate=${K8S_SSL}/kubelet.pem \
        --client-key=${K8S_SSL}/kubelet-key.pem \
        --embed-certs=true \
        --kubeconfig=kubelet.kubeconfig

      kubectl config set-context default \
        --cluster=kubernetes \
        --user=node \
        --kubeconfig=kubelet.kubeconfig

      kubectl config use-context default --kubeconfig=kubelet.kubeconfig
    popd
}

generate_r6d(){
    echo "create region.goodrain.me ca"
    grcert create --is-ca --ca-name=${CA_PATH}/ca.pem --ca-key-name=${CA_PATH}/ca.key.pem
    echo "create region.goodrain.me server"
    grcert create --ca-name=${CA_PATH}/ca.pem --ca-key-name=${CA_PATH}/ca.key.pem --crt-name=${CA_PATH}/server.pem --crt-key-name=${CA_PATH}/server.key.pem --domains region.goodrain.me --address=${MIP} --address=127.0.0.1
    echo "create region.goodrain.me client"
    grcert create --ca-name=${CA_PATH}/ca.pem --ca-key-name=${CA_PATH}/ca.key.pem --crt-name=${CA_PATH}/client.pem --crt-key-name=${CA_PATH}/client.key.pem --domains region.goodrain.me --address=${MIP} --address=127.0.0.1
}

case $ACTION in
    sh|bash)
        exec /bin/bash
    ;;
    *)
        [ ! -f "$K8S_SSL/ca.pem" ] && generate_ssl
        [ ! -f "$K8S_CFG/admin.kubeconfig" ] && generate_k8s 
        if [ -f "/grdata/kubernetes/kube-proxy.kubeconfig" ]; then
            diff /grdata/kubernetes/kube-proxy.kubeconfig $K8S_CFG/kube-proxy.kubeconfig
            [ "$?" -ne 0 ] && cp -a $K8S_CFG/kube-proxy.kubeconfig /grdata/kubernetes/kube-proxy.kubeconfig && chmod 600 /grdata/kubernetes/kube-proxy.kubeconfig 
        else
            cp -a $K8S_CFG/kube-proxy.kubeconfig /grdata/kubernetes/kube-proxy.kubeconfig
            chmod 600 /grdata/kubernetes/kube-proxy.kubeconfig
        fi
        [ ! -f "${CA_PATH}/server.key.pem" ] && generate_r6d
        exec /bin/bash
    ;;
esac