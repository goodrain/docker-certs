#!/bin/bash

KUBE_VERSION=v1.10.13
#KUBE_APISERVER="https://127.0.0.1:6443"
KUBE_APISERVER="https://kubeapi.goodrain.me:6443"


if [ ! -z $K8S_VER ];then
    KUBE_VERSION=$K8S_VER
fi

if [ ! -z $API  ];then
    KUBE_APISERVER=$API
fi

export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')

create_token(){
cat > token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
}

create_bootstrap_kubeconfig(){
      kubectl config set-cluster kubernetes \
        --certificate-authority=/etc/goodrain/kubernetes/ssl/ca.pem \
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
}

create_kube_proxy_kubeconfig(){
      kubectl config set-cluster kubernetes \
        --certificate-authority=/etc/goodrain/kubernetes/ssl/ca.pem \
        --embed-certs=true \
        --server=${KUBE_APISERVER} \
        --kubeconfig=kube-proxy.kubeconfig

      kubectl config set-credentials kube-proxy \
        --client-certificate=/etc/goodrain/kubernetes/ssl/kube-proxy.pem \
        --client-key=/etc/goodrain/kubernetes/ssl/kube-proxy-key.pem \
        --embed-certs=true \
        --kubeconfig=kube-proxy.kubeconfig

      kubectl config set-context default \
        --cluster=kubernetes \
        --user=kube-proxy \
        --kubeconfig=kube-proxy.kubeconfig

      kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}

create_admin_kubeconfig(){
    kubectl config set-cluster kubernetes \
        --certificate-authority=/etc/goodrain/kubernetes/ssl/ca.pem \
        --embed-certs=true \
        --server=${KUBE_APISERVER} \
        --kubeconfig=admin.kubeconfig

      kubectl config set-credentials admin \
        --client-certificate=/etc/goodrain/kubernetes/ssl/admin.pem \
        --client-key=/etc/goodrain/kubernetes/ssl/admin-key.pem \
        --embed-certs=true \
        --kubeconfig=admin.kubeconfig

      kubectl config set-context default \
        --cluster=kubernetes \
        --user=admin \
        --kubeconfig=admin.kubeconfig

      kubectl config use-context default --kubeconfig=admin.kubeconfig

}

create_kubelet_kubeconfig(){
   kubectl config set-cluster kubernetes \
        --certificate-authority=/etc/goodrain/kubernetes/ssl/ca.pem \
        --embed-certs=true \
        --server=${KUBE_APISERVER} \
        --kubeconfig=kubelet.kubeconfig

      kubectl config set-credentials node \
        --client-certificate=/etc/goodrain/kubernetes/ssl/kubelet.pem \
        --client-key=/etc/goodrain/kubernetes/ssl/kubelet-key.pem \
        --embed-certs=true \
        --kubeconfig=kubelet.kubeconfig

      kubectl config set-context default \
        --cluster=kubernetes \
        --user=node \
        --kubeconfig=kubelet.kubeconfig

      kubectl config use-context default --kubeconfig=kubelet.kubeconfig
}

run(){
    create_token
    create_bootstrap_kubeconfig
    create_kube_proxy_kubeconfig
    create_admin_kubeconfig
    create_kubelet_kubeconfig
}

case $1 in
    bash)
        exec /bin/bash
    ;;
    *)
        run
    ;;
esac