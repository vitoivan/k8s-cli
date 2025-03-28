#!/bin/bash

k8_get_ctxs() {
    kubectl config get-contexts | awk '{ print $2 }' | grep -v NAME | xargs
}

k8_cur_ctx() {
    kubectl config current-context
}

k8_use_ctx() {
    kubectl config use-context $1
}

k8_get_ns() {
    kubectl get namespaces | awk '{print $1}' | grep -v NAME | xargs
}


## $1 == namespace
k8_get_pods() {
    kubectl get pods -n $1 | awk '{print $1}' | grep -v NAME | xargs
}

## $1 == namespace
k8_get_services() {
    kubectl get services -n $1
}




## $1 == namespace & $2 == service name
k8_log_from_service() {
    c="digimalls"
    kubectl logs -f --container $c -n $1 service/$2
}

## $1 == namespace & $2 == pod name
k8_log_from_pod() {
    c="digimalls"
    kubectl logs -f --container $c -n $1 pod/$2
}

## $1 == namespace & $2 == pod name
k8_get_pod_metrics() {
    kubectl top pod $2 --namespace=$1 
}

if [ "$1" == "" ]; then
    return
elif [ "$1" == "k8_get_ctxs" ]; then
    k8_get_ctxs
elif [ "$1" == "k8_cur_ctx" ]; then
    k8_cur_ctx
elif [ "$1" == "k8_use_ctx" ]; then
    k8_use_ctx $2
elif [ "$1" == "k8_get_ns" ]; then
    k8_get_ns
elif [ "$1" == "k8_get_pods" ]; then
    k8_get_pods $2
elif [ "$1" == "k8_get_services" ]; then
    k8_get_services $2
elif [ "$1" == "k8_log_from_service" ]; then
    k8_log_from_service $2 $3
elif [ "$1" == "k8_log_from_pod" ]; then
    k8_log_from_pod $2 $3
elif [ "$1" == "k8_get_pod_metrics" ]; then
    k8_get_pod_metrics $2 $3
else
    echo "unknown command"
fi


