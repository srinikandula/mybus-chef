#!/usr/bin/env bash
#
# Creates an ELB suitable for use by an ECS device graph service.
#
#
# ./create_dg_elb.sh -n ecs-ube-dev-dev-graph-collector --instance-port 8721
# ./create_dg_elb.sh -n ecs-mid-pilot-dev-dg-coll --instance-port 8721
# ./create_dg_elb.sh -n ecs-mid-demo-dg-coll --instance-port 8721
#
# ./create_dg_elb.sh -n ecs-ube-dev-dg-query --instance-port 8722
# ./create_dg_elb.sh -n ecs-mid-pilot-dev-dg-query  --instance-port 8722
# ./create_dg_elb.sh -n ecs-mid-demo-dg-query --instance-port 8722
#


function usage() {
    set -e
    cat <<EOM
    ##### create_dg_elb #####
    Simple script for creating an ELB for use on Amazon EC2 Container Service for a Device Graph service

    One of the following is required:
        -n | --name                 Name of ELB to create (or delete or describe)
        -i | --instance-port        Port number of the EC2 instance in the ECS cluster, NOT the container port

    Other parameters:
        -k | --aws-access-key        AWS Access Key ID. May also be set as environment variable AWS_ACCESS_KEY_ID
        -s | --aws-secret-key        AWS Secret Access Key. May also be set as environment variable AWS_SECRET_ACCESS_KEY
        -u | --subnets
        -s | --security-groups
        -c | --scheme
        -p | --elb-port

        -x | --delete                Delete the load balancer.  (All other params are ignored)

        -d | --describe              Describe the ELB. (All other params are ignored)

EOM
    exit 2
}

if [ $# == 0 ]; then usage; fi


elb_name=""
subnets="subnet-07df334e"  # if multiple, separate with spaces.  A subnet is needed for VPC
security_groups="sg-11dac76a sg-90425ceb"  # if multiple, separate with spaces
scheme="internet-facing"
listener_elb_port=80
listener_elb_ssl_port=443
listener_instance_port=""    # for ECS, this is the port of the ECS instance (host port), not the container port
delete_elb=false
describe_elb=false

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
        -n|--name)
            elb_name="$2"
            shift # past argument
            ;;
        -u|--subnets)
            subnets="$2"
            shift # past argument
            ;;
        -s|--security-groups)
            security_groups="$2"
            shift # past argument
            ;;
        -c|--scheme)
            scheme="$2"
            shift
            ;;
        -i|--instance-port)
            listener_instance_port="$2"
            shift
            ;;
        -p|--elb-port)
            listener_elb_port="$2"
            shift
            ;;
        -x|--delete)
            delete_elb=true
            ;;
        -d|--describe)
            describe_elb=true
            ;;
        *)
            usage
            exit 2
        ;;
    esac
    shift # past argument or value
done

if [[ ${elb_name} == "" ]]; then usage; fi

set -e

if [ ${describe_elb} == true ]; then
    aws elb describe-load-balancers --load-balancer-names ${elb_name}
    echo ""
elif [ ${delete_elb} == true ]; then
    echo "deleting elb ${elb_name}..."
    aws elb delete-load-balancer --load-balancer-name ${elb_name}
    echo "${elb_name} deleted successfully"
else
    if [[ ${listener_instance_port} == "" ]]; then usage; fi

    echo "creating elb ${elb_name}..."

    aws elb create-load-balancer --load-balancer-name ${elb_name} \
      --listeners "Protocol=HTTP,LoadBalancerPort=${listener_elb_port},InstanceProtocol=HTTP,InstancePort=${listener_instance_port}" \
      "Protocol=TCP,LoadBalancerPort=${listener_elb_ssl_port},InstanceProtocol=TCP,InstancePort=${listener_instance_port}" \
      --subnets ${subnets} --security-groups ${security_groups} \
      --scheme ${scheme}

    echo "elb ${elb_name} created."

    echo "configuring healthcheck..."
    aws elb configure-health-check --load-balancer-name ${elb_name} --health-check "Target=HTTP:${listener_instance_port}/healthcheck,Interval=30,UnhealthyThreshold=2,HealthyThreshold=3,Timeout=5"

    echo "healthcheck configured successfully."

    echo "ELB info:"

    aws elb describe-load-balancers --load-balancer-names ${elb_name}

    printf "\n\n${elb_name} created and configured successfully.\n\n"

fi





