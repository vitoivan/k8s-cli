#!/bin/bash

here=$(dirname $0)
main_menu=$(echo "k8s cache" | tr " " "\n")
actions=$(echo "port-forward logs describe-pod pod-metrics" | tr " " "\n")
k8s_path="$here/k8s.sh"


green() {
    text=$1
    echo "$(tput setaf 2)$text$(tput sgr0)"
}

handle_db_flow() {
    if [ "$menu_seleceted_opt" == "cache" ]; then
        db_opts=$(echo "reset" | tr " " "\n")
        db_seleceted_opt=$(echo "$db_opts" | fzf --header="select an option" --header-first)

        if [ "$db_seleceted_opt" == "reset" ]; then
            $here/database reset
        fi
    fi }


handle_k8s_flow(){
    if [ "$menu_seleceted_opt" == "k8s" ]; then
        contexts=$($k8s_path k8_get_ctxs | tr " " "\n")
         
        selected_ctx=$(echo "$contexts" | fzf --header="select a context" --header-first)

        if [ "$selected_ctx" == "" ]; then
            return
        fi

        $k8s_path k8_use_ctx $selected_ctx

        namespaces=$($k8s_path k8_get_ns | tr " " "\n")

        selected_ns=$(echo "$namespaces" | fzf --header="select a namespace" --header-first)

        if [ "$selected_ns" == "" ]; then
           return
        fi

        ns_pretty=$(green $selected_ns)
        echo "Selected namespace: $ns_pretty"

        selected_action=$(echo "$actions" | fzf --header="select an action" --header-first)

        if [ "$selected_action" == "" ]; then
            return
        fi

        if [ "$selected_action" == "port-forward" ]; then
            handle_port_forward
        elif [ "$selected_action" == "logs" ]; then
            handle_logs
        elif [ "$selected_action" == "describe-pod" ]; then
            handle_describe_pod
        elif [ "$selected_action" == "pod-metrics" ]; then
            handle_pod_metrics
        fi
    fi
}


handle_port_forward() {
    forward_mode=$(echo "pod service" | tr " " "\n")
    selected_mode=$(echo "$forward_mode" | fzf --header="select a mode to forward" --header-first)

    if [ "$selected_mode" == "" ]; then
        return
    fi

    if [ "$selected_mode" == "pod" ]; then
        pods=$($k8s_path k8_get_pods $selected_ns | tr " " "\n")
        selected_pod=$(echo "$pods" | fzf --header="select a pod" --header-first)

        if [ "$selected_pod" == "" ]; then
            return
        fi

        read -p "enter the ports <host-port>:<service-port>: " ports

        if [ "$ports" == "" ]; then
            return
        fi

        kubectl port-forward $selected_pod -n $selected_ns $ports 

    elif [ "$selected_mode" == "service" ]; then

        raw_services=$($k8s_path k8_get_services $selected_ns)
        services=$(echo "$raw_services" | awk '{print $1}' | grep -v NAME | tr " " "\n")
        selected_service=$(echo "$services" | fzf --header="select a service" --header-first)

        if [ "$selected_service" == "" ]; then
            return
        fi

        service_ports=$(                    \
                echo "$raw_services"    |   \
                awk '{print $5}'        |   \
                grep -v PORT            |   \
                tr " " "\n"             |   \
                tr "," "\n"             |   \
                awk -F":" '{print $1}'  |   \
                sed 's/\/TCP//')

        if [ "$service_ports" == "" ]; then
            echo "error: service port not found"
            return
        fi

        read -p "enter the host port: " port

        if [ "$port" == "" ]; then
            return
        fi

        selected_service_port=$(echo "$service_ports" | fzf --header="select the service port" --header-first)

        if [ "$selected_service_port" == "" ]; then
            return
        fi

        kubectl port-forward services/$selected_service -n $selected_ns $port:$selected_service_port
    fi
}


handle_describe_pod() {
    pods=$($k8s_path k8_get_pods $selected_ns | tr " " "\n") 

    selected_pod=$(echo "$pods" | fzf --header="select a pod" --header-first)

    if [ "$selected_pod" == "" ]; then
        return
    fi

    kubectl describe pod $selected_pod -n $selected_ns
}

handle_pod_metrics() {
    pods=$($k8s_path k8_get_pods $selected_ns | tr " " "\n") 

    selected_pod=$(echo "$pods" | fzf --header="select a pod" --header-first)

    if [ "$selected_pod" == "" ]; then
        return
    fi

    kubectl top pod $selected_pod --namespace=$selected_ns 
}


handle_logs() {
    modes=$(echo "pod service" | tr " " "\n")
    selected_mode=$(echo "$modes" | fzf --header="select a mode" --header-first)

    if [ "$selected_mode" == "" ]; then
        return
    fi

    if [ "$selected_mode" == "pod" ]; then
        pods=$($k8s_path k8_get_pods $selected_ns| tr " " "\n")
        selected_pod=$(echo "$pods" | fzf --header="select a pod" --header-first)

        if [ "$selected_pod" == "" ]; then
            return
        fi

        $k8s_path k8_log_from_pod $selected_ns $selected_pod

    elif [ "$selected_mode" == "service" ]; then
        raw_services=$($k8s_path k8_get_services $selected_ns)
        services=$(echo "$raw_services" | awk '{print $1}' | grep -v NAME | tr " " "\n")
        selected_service=$(echo "$services" | fzf --header="select a service" --header-first)

        if [ "$selected_service" == "" ]; then
            return
        fi

        $k8s_path k8_log_from_service $selected_ns $selected_service

    fi
}


main() {
    # menu_seleceted_opt=$(echo "$main_menu" | fzf --header="select an option" --header-first)
    menu_seleceted_opt="k8s"

    # handle_db_flow
    handle_k8s_flow
}


main
