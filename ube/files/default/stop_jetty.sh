#!/bin/bash
#
# usage:  stop_jetty.sh
#

set -ex

printf "\n---- $0 ----\n\n"

sudo_prefix=""

set +e
jetty_cmd="`which jetty`"
set -e
printf "detecting jetty launch command...\n"
if [ -e /etc/init.d/jetty ]; then
    printf "detected /etc/init.d/jetty  (Ubuntu)\n\n"
    jetty_cmd="sudo service jetty"
    sudo_prefix="sudo "
elif [ -n "$jetty_cmd" ]; then
    printf "detected a jetty executable - %s\n\n", jetty_cmd
else
    printf "Error.  Could not find the jetty executable.  exiting.\n\n"
    exit 1
fi


if [ -z "$JETTY_HOME" ] ; then
    # attempt to find jetty home
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


${jetty_cmd} stop

# clean out the work directory
${sudo_prefix}rm -rf "${JETTY_HOME}/work"
${sudo_prefix}mkdir -p "${JETTY_HOME}/work"
