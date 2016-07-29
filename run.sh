#!/bin/bash

# Swarm Size. (default is 3)
if [ -z "${SWARM_SIZE}" ]; then
    SWARM_SIZE=3
fi

# By default, 'virtualbox' will be used, you can set 'DOCKER_MACHINE_DRIVER' to override it.
if [ -z "${DOCKER_MACHINE_DRIVER}" ]; then
    DOCKER_MACHINE_DRIVER=virtualbox
fi

# CN_SPECIAL_OPTS="--engine-registry-mirror https://jxus37ac.mirror.aliyuncs.com"
INSECURE_OPTS="--engine-insecure-registry 192.168.99.0/24"
# STORAGE_OPTS="--engine-storage-driver overlay2"

MACHINE_OPTS="${STORAGE_OPTS} ${INSECURE_OPTS} ${CN_SPECIAL_OPTS}"

##############################
#      Image Management      #
##############################

function build() {
    # Build images
    docker build -t ${REGISTRY_USER}/lnmp-nginx:latest -f nginx-php/Dockerfile.nginx ./nginx-php
    docker build -t ${REGISTRY_USER}/lnmp-php:latest -f nginx-php/Dockerfile.php-alpine ./nginx-php
    docker build -t ${REGISTRY_USER}/lnmp-mysql:latest -f mysql/Dockerfile ./mysql
}

function push() {
    # Push to the registry
    docker push ${REGISTRY_USER}/lnmp-nginx:latest
    docker push ${REGISTRY_USER}/lnmp-php:latest
    docker push ${REGISTRY_USER}/lnmp-mysql:latest
}

function publish() {
    # Get username
    REGISTRY_USER=$(docker info | awk '/Username/ { print $2 }')

    if [ -z "${REGISTRY_USER}" ]; then
        # Login first, so we can get the user name directly
        echo "Please login first: 'docker login'"
        exit 1
    fi

    # Build Images
    build

    # Push to Registry
    push
}

##############################
#  Swarm Cluster Preparation #
##############################

function create_store() {
    NAME=$1
    docker-machine create -d ${DOCKER_MACHINE_DRIVER} ${MACHINE_OPTS} ${NAME}
    eval "$(docker-machine env ${NAME})"
    HostIP="$(docker-machine ip ${NAME})"
    export KVSTORE="etcd://${HostIP}:2379"
    docker run -d \
        -p 4001:4001 -p 2380:2380 -p 2379:2379 \
        --restart=always \
        --name etcd \
        twang2218/etcd:v2.3.7 \
            --initial-advertise-peer-urls http://${HostIP}:2380 \
            --initial-cluster default=http://${HostIP}:2380 \
            --advertise-client-urls http://${HostIP}:2379,http://${HostIP}:4001 \
            --listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
            --listen-peer-urls http://0.0.0.0:2380
}

function create_master() {
    NAME=$1
    echo "kvstore is ${KVSTORE}"
    # eth1 on virtualbox, eth0 on digitalocean
    docker-machine create -d ${DOCKER_MACHINE_DRIVER} ${MACHINE_OPTS} \
        --swarm \
        --swarm-discovery=${KVSTORE} \
        --swarm-master \
        --engine-opt="cluster-store=${KVSTORE}" \
        --engine-opt="cluster-advertise=eth1:2376" \
        ${NAME}
}

function create_node() {
    NAME=$1
    echo "kvstore is ${KVSTORE}"
    # eth1 on virtualbox, eth0 on digitalocean
    docker-machine create -d ${DOCKER_MACHINE_DRIVER} ${MACHINE_OPTS} \
        --swarm \
        --swarm-discovery=${KVSTORE} \
        --engine-opt="cluster-store=${KVSTORE}" \
        --engine-opt="cluster-advertise=eth1:2376" \
        ${NAME}
}

function create() {
    create_store kvstore
    create_master master
    for i in $(seq 1 ${SWARM_SIZE})
    do
        create_node node${i} &
    done

    wait
}

function remove() {
    for i in $(seq 1 ${SWARM_SIZE})
    do
        docker-machine rm -y node${i} || true
    done
    docker-machine rm -y master || true
    docker-machine rm -y kvstore || true
}

##############################
#     Service Management     #
##############################

function up() {
    eval "$(docker-machine env --swarm master)"
    docker-compose up -d
}

function scale() {
    echo $#
}

function down() {
    eval "$(docker-machine env --swarm master)"
    docker-compose down
}

##############################
#         Entrypoint         #
##############################

function main() {
    Command=$1
    shift
    case "${Command}" in
        create)     create ;;
        remove)     remove ;;
        up)         up ;;
        scale)      scale "$@" ;;
        down)       down ;;
        publish)    publish ;;
        *)          echo "Usage: $0 <create|remove|up|scale|down|publish>"; exit 1 ;;
    esac
}

main "$@"
