#!/bin/bash
#
# usage:  start_jetty.sh <war_file>
#
# This script will start Jetty, using the specified war file.  It will
# stop jetty if it is currently running.  It will also clean out
# jetty's "work" directory.  It also updates a symlink that is used
# to point to the current war file.
#
# note: please ensure JETTY_HOME is set, or else this script won't work.
#


set -ex

printf "\n---- $0 ----\n\n"

# base dir is the base dir of the ube project
basedir="`dirname $0`/.."
pushd "$basedir" > /dev/null 2>&1


sudo_prefix=""

# set JAVA_OPTIONS for SQS queue names
if [ -n "$SQS_OUTGOING_QUEUE" -a -n "$SQS_INCOMING_QUEUE" ] ; then
    printf "SQS queue names were defined.  Adding them to JAVA_OPTIONS\n"
    export JAVA_OPTIONS="$JAVA_OPTIONS -Daws.sqs.jobrunner.command.queue=$SQS_OUTGOING_QUEUE -Daws.sqs.jobrunner.callback.queue=$SQS_INCOMING_QUEUE"
fi

set +e
jetty_cmd="`which jetty`"
set -e
printf "detecting jetty launch command...\n"
if [ -e /etc/init.d/jetty ]; then
    printf "detected /etc/init.d/jetty  (Ubuntu)\n\n"
    jetty_cmd="sudo service jetty"
    sudo_prefix="sudo "
elif [ -n "$jetty_cmd" ]; then
    printf "detected a jetty executable - %s\n\n", "$jetty_cmd"
else
    printf "Error.  Could not find the jetty executable.  exiting.\n\n"
    exit 1
fi


if [ -z "$JETTY_HOME" ] ; then
    set +e
    jetty_home=$($jetty_cmd status | grep JETTY_HOME | awk '{print $3}')
    set -e
    if [[ -n "$jetty_home" ]]; then
        export JETTY_HOME=$jetty_home
    else
        printf "JETTY_HOME is not set\n"
        exit 1
    fi
fi

pwd=`pwd`
war_file_param="$1"

if [ ! -f "$war_file_param" ] ; then
    printf "No war file was specified on the command line\n\n"
    exit 1
fi

absolute_war_file=""
sed_results="`echo ${war_file_param} | sed -n '/^\//p'`"
if [ -n "$sed_results" ] ; then
    absolute_war_file=${war_file_param}
else
    absolute_war_file="`pwd`/`dirname ${war_file_param}`/${war_file_param##*/}"
fi

war_file=${absolute_war_file}
printf "war file is ${war_file}\n"




printf "Stopping jetty...\n\n"
${jetty_cmd} stop

# This next line will get rid of error messages seen when using 'ps' on Mac OSX
[ -z "$DYLD_LIBRARY_PATH" ] || unset DYLD_LIBRARY_PATH

SCRIPT_TIMEOUT_IN_SECONDS=60
polling_interval_in_seconds=2

pid_count=999
function count_jetty_pids() {
  set +e
  pid_count=`ps -e -o pid,command | grep '[j]ava.*jetty.*daemon' | sed 's/^ //' | cut -f1 -d' ' | wc -l`
#  pid_count=`ps -e -o pid,command | grep "[j]ava.*jetty" | sed 's/^ //' | cut -f1 -d' ' | wc -l`
  set -e
}

start_time=$(date +%s)
count_jetty_pids
while (( $pid_count > 0 )); do
    printf "jetty is still running.  waiting $polling_interval_in_seconds before checking again\n"
	sleep "${polling_interval_in_seconds}s"
	current_time=$(date +%s)
	elapsed_time=$(( $current_time - $start_time ))
	if (( $elapsed_time > SCRIPT_TIMEOUT_IN_SECONDS )); then
		printf "Timeout occurred before jetty could be stopped.\n"
		exit 1
	fi
	count_jetty_pids
done


printf "Removing old war link...\n"
[ -f "${JETTY_HOME}/webapps/ube-link/ube.war" ] && ${sudo_prefix}rm "${JETTY_HOME}/webapps/ube-link/ube.war"
[ -f "${JETTY_HOME}/contexts/ube-link/ube.war" ] && ${sudo_prefix}rm "${JETTY_HOME}/contexts/ube-link/ube.war"

if [ ! -f "${pwd}/etc/ube-jetty.xml" ]; then
    printf "Can't find ube-jetty.xml.  pwd is: '`pwd`'  basedir is '${basedir}'.  Exiting with error code.\n"
    exit 1
fi
webapps_or_ctx=""
if [ -d ${JETTY_HOME}/contexts ]; then
    webapps_or_ctx="contexts"
else
    webapps_or_ctx="webapps"
fi
printf "Copying ube-jetty.xml config file to JETTY_HOME/$webapps_or_ctx...\n\n"
${sudo_prefix}cp "${pwd}/etc/ube-jetty.xml" "${JETTY_HOME}/${webapps_or_ctx}/"

# set flag to indicate if this is being run on ubuntu
if [ "`id -un`" = "ubuntu" ]; then is_ubuntu=true; else is_ubuntu=false; fi

if ( ${is_ubuntu} ); then
    # if running on ubuntu instance, create 2 sym links for convenience in the
    # ubuntu user's home directory, 'ube' and 'ube-node'
    ln -sfn /mnt/ube_deployments/ube ~/ube
    ln -sfn /mnt/ube_deployments/ube/build/distributions ~/ube-node

    # clean out tmp dir on ubuntu
    jetty_tmp_dir="/mnt/jetty_java_io_tmp"
    sudo rm -rf "${jetty_tmp_dir}/*"
fi

# clean out the work directory (non-ubuntu)
${sudo_prefix}rm -rf "${JETTY_HOME}/work"
${sudo_prefix}mkdir -p "${JETTY_HOME}/work"

${sudo_prefix}mkdir -p "${JETTY_HOME}/${webapps_or_ctx}/ube-link"
${sudo_prefix}ln -sfn "${war_file}" "${JETTY_HOME}/${webapps_or_ctx}/ube-link/ube.war"

${jetty_cmd} start

#ubuntu@ip-10-164-6-200:/opt/jetty/start.d$ sudo service jetty status | grep "pid=" | sed s/*=*//
#Jetty running pid=391
#ubuntu@ip-10-164-6-200:/opt/jetty/start.d$ sudo service jetty status | grep "pid=" | cut -d '=' -f2
#391

set +e
launch_jetty_pid="$(${jetty_cmd} status | grep "pid=" | cut -d '=' -f2)"
set -e
echo "pid of ${jetty_cmd} start: $launch_jetty_pid"
# the launch_jetty_pid process launches jetty as a sub process.
# we know that the jetty sub process is fully launched once the launch_jetty_pid process has finished
# so sit in a loop sleeping until the launch_jetty_pid has finished launching jetty
current_jetty_pid="$(ps -A | grep ${launch_jetty_pid} | grep -v grep)"
while [ -z "$current_jetty_pid" ]; do
    sleep 2s
    current_jetty_pid="$(ps -A | grep ${launch_jetty_pid} | grep -v grep)"
done

printf "Jetty has been launched...\n\n"
