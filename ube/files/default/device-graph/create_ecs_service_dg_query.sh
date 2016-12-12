#!/usr/bin/env bash


function usage() {
    set -e
    cat <<EOM
    ##### create_ecs_task_def_dg_collection #####
    Simple script for creating an ELB for use on Amazon EC2 Container Service for a Device Graph service

    All of the following are required:
        -c | --cluster
        -e | --elb-name

    Other parameters:
        -k | --aws-access-key        AWS Access Key ID. May also be set as environment variable AWS_ACCESS_KEY_ID
        -s | --aws-secret-key        AWS Secret Access Key. May also be set as environment variable AWS_SECRET_ACCESS_KEY
        -h | --host-port
        -c | --container-port


EOM
    exit 2
}


BUILD_NUMBER=""
CLUSTER=""
SERVICE_NAME="dev-graph-collector"
TASK_DEF_NAME="dev-graph-collector"
TASK_ROLE="ecsServiceRole"
CONTAINER_PORT=8787
HOST_PORT=8721
ELB_NAME=""


# Loop through arguments, two at a time for key and value
while [[ $# > 0 ]]
do
    key="$1"

    case $key in
        -k|--aws-access-key)
            AWS_ACCESS_KEY_ID="$2"
            shift # past argument
            ;;
        -s|--aws-secret-key)
            AWS_SECRET_ACCESS_KEY="$2"
            shift # past argument
            ;;
        -c|--cluster)
            CLUSTER="$2"
            shift # past argument
            ;;
        -p|--container-port)
            CONTAINER_PORT="$2"
            shift # past argument
            ;;
        -e|--elb-name)
            ELB_NAME="$2"
            shift
            ;;
        *)
            usage
            exit 2
        ;;
    esac
    shift # past argument or value
done


if [[ ${ELB_NAME} == "" ]]; then usage; fi


aws ecs create-service --cluster ${CLUSTER} --service-name ${SERVICE_NAME} --task-definition ${TASK_DEF_NAME} \
    --load-balancers loadBalancerName=${ELB_NAME},containerName=${TASK_DEF_NAME},containerPort=${CONTAINER_PORT} \
    --role ${TASK_ROLE} --desired-count 0
