#!/usr/bin/env bash
#
#
# You only need to run this 3 times, ever (in theory) -- once for each app.  You do not need to
# repeat for each cluster.
#
# The parameters for cluster and build-number are help to construct


function usage() {
    set -e
    cat <<EOM
    ##### create_ecs_task_def_dg_collection #####
    Simple script for creating an ELB for use on Amazon EC2 Container Service for a Device Graph service

    All of the following are required:
        -a | --app                   Value must be one of [collection | query | queue]
        -b | --build-number
        -c | --cluster

    Other parameters:
        -k | --aws-access-key        AWS Access Key ID. May also be set as environment variable AWS_ACCESS_KEY_ID
        -s | --aws-secret-key        AWS Secret Access Key. May also be set as environment variable AWS_SECRET_ACCESS_KEY
        -h|--host-port
        -p|--container-port


EOM
    exit 2
}

if [ $# == 0 ]; then usage; fi




APP_NAME=""

BUILD_NUMBER=""
CLUSTER=""


TASK_ROLE="ecsServiceRole"
HOST_PORT=""
HOST_PORT_COLLECTION=8721
HOST_PORT_QUERY=8722
HOST_PORT_QUEUE_PROC=8723

CONTAINER_PORT=""
CONTAINER_PORT_COLLECTION=8787
CONTAINER_PORT_QUERY=8686
CONTAINER_PORT_QUEUE_PROC=8585

SERVICE_NAME=""
SERVICE_NAME_COLLECTION="dev-graph-collector"
SERVICE_NAME_QUERY="dev-graph-query"
SERVICE_NAME_QUEUE_PROCESSOR="dev-graph-queue-proc"

IMG_NAME=
IMG_NAME_COLLECTION="dev-graph-collector"
IMG_NAME_QUERY="dev-graph-query"
IMG_NAME_QUEUE_PROC="dev-graph-queue-proc"

REPO=""
REPO_COLLECTION="853097395290.dkr.ecr.us-east-1.amazonaws.com/dev-graph-collector"
REPO_QUERY="853097395290.dkr.ecr.us-east-1.amazonaws.com/dev-graph-query"
REPO_QUEUE_PROC="853097395290.dkr.ecr.us-east-1.amazonaws.com/dev-graph-queue-proc"


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
        -a|--app)
            APP_NAME="$2"
            shift # past argument
            [[ ${APP_NAME} =~ ^collection|query|queue$ ]] || usage
            ;;
        -b|--build-number)
            BUILD_NUMBER="$2"
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
        -h|--host-port)
            HOST_PORT="$2"
            shift # past argument
            ;;
        *)
            usage
            exit 2
        ;;
    esac
    shift # past argument or value
done


if [[ ${CLUSTER} == "" ]]; then usage; fi
if [[ ${BUILD_NUMBER} == "" ]]; then usage; fi
if [[ ${APP_NAME} == "" ]]; then usage; fi



if [[ ${APP_NAME} == "collection" ]]; then
    [[ "${HOST_PORT}" = "" ]] && HOST_PORT=${HOST_PORT_COLLECTION}
    [[ "${CONTAINER_PORT}" = "" ]] && CONTAINER_PORT=${CONTAINER_PORT_COLLECTION}
    SERVICE_NAME=${SERVICE_NAME_COLLECTION}
    REPO=${REPO_COLLECTION}
elif [[ ${APP_NAME} == "query" ]]; then
    [[ "${HOST_PORT}" = "" ]] && HOST_PORT=${HOST_PORT_QUERY}
    [[ "${CONTAINER_PORT}" = "" ]] && CONTAINER_PORT=${CONTAINER_PORT_QUERY}
    SERVICE_NAME=${SERVICE_NAME_QUERY}
    REPO=${REPO_QUERY}
elif [[ ${APP_NAME} == "queue" ]]; then
    [[ "${HOST_PORT}" = "" ]] && HOST_PORT=${HOST_PORT_QUEUE_PROC}
    [[ "${CONTAINER_PORT}" = "" ]] && CONTAINER_PORT=${CONTAINER_PORT_QUEUE_PROC}
    SERVICE_NAME=${SERVICE_NAME_QUEUE_PROCESSOR}
    REPO=${REPO_QUEUE_PROC}
else
    usage
fi



json_filename=/tmp/dg_${APP_NAME}_task_def_b${BUILD_NUMBER}.json

set -e

cat > ${json_filename} <<EOM
{
    "family": "${SERVICE_NAME}",
    "volumes": [
        {
          "host": {
            "sourcePath": "/root"
          },
          "name": "root-home"
        }
      ],
    "containerDefinitions": [
        {
            "image": "${REPO}:b${BUILD_NUMBER}",
            "name": "${SERVICE_NAME}",
            "cpu": 0,
            "memory": 256,
            "essential": true,
            "portMappings": [
                {
                    "containerPort": ${CONTAINER_PORT},
                    "hostPort": ${HOST_PORT},
                    "protocol": "tcp"
                }
            ],
            "mountPoints": [
                {
                  "containerPath": "/host-home-mount",
                  "readOnly": true,
                  "sourceVolume": "root-home"
                }
              ],
            "volumesFrom": [],
            "environment": [
                {
                  "value": "/host-home-mount/dev_graph_${CLUSTER}_${APP_NAME}_b${BUILD_NUMBER}.js",
                  "name": "DEV_GRAPH_CONFIG_FILE"
                }
            ]
        }
    ]
}
EOM

#cat ${json_filename}

aws ecs register-task-definition --cli-input-json file://${json_filename}

[[ "$?" == "0" ]] && echo "Task creation completed successfully."

# example output from:
# aws ecs describe-task-definition --task-def arn:aws:ecs:us-east-1:853097395290:task-definition/dev-graph-collector:15
#
#{
#    "taskDefinition": {
#        "volumes": [
#            {
#                "name": "root-home",
#                "host": {
#                    "sourcePath": "/root"
#                }
#            }
#        ],
#        "taskDefinitionArn": "arn:aws:ecs:us-east-1:853097395290:task-definition/dev-graph-collector:15",
#        "revision": 15,
#        "requiresAttributes": [
#            {
#                "name": "com.amazonaws.ecs.capability.ecr-auth"
#            }
#        ],
#        "status": "ACTIVE",
#        "family": "dev-graph-collector",
#        "containerDefinitions": [
#            {
#                "volumesFrom": [],
#                "environment": [
#                    {
#                        "value": "/host-home-mount/dev_graph_ube-dev-dg-cluster_collection_b1426.js",
#                        "name": "DEV_GRAPH_CONFIG_FILE"
#                    }
#                ],
#                "mountPoints": [
#                    {
#                        "sourceVolume": "root-home",
#                        "readOnly": true,
#                        "containerPath": "/host-home-mount"
#                    }
#                ],
#                "name": "dev-graph-collector",
#                "portMappings": [
#                    {
#                        "hostPort": 8721,
#                        "containerPort": 8787,
#                        "protocol": "tcp"
#                    }
#                ],
#                "cpu": 0,
#                "image": "853097395290.dkr.ecr.us-east-1.amazonaws.com/dev-graph-collector:b1426",
#                "memory": 128,
#                "essential": true
#            }
#        ]
#    }
#}