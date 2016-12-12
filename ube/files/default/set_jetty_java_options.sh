#!/bin/bash

config_file=/etc/default/jetty
java_options=$@

function usage() {
   printf "Usage:\n\n"
   printf "$0 [JVM_option_1] [JVM_option_2] .. [JVM_option_n]\n\n"
   exit 1
}

backup_timestamp=`date +%Y%m%d-%H%M%S`
backup_filename="${config_file}.BACKUP.${backup_timestamp}"

if grep 'export JAVA_OPTIONS=' ${config_file} ; then
	sudo sed --in-place=".BACKUP.${backup_timestamp}" "s~^export JAVA_OPTIONS=.*$~export JAVA_OPTIONS=${java_options}~" ${config_file}
else
	sudo cp ${config_file} "${config_file}.BACKUP.${backup_timestamp}"
	sudo echo "export JAVA_OPTIONS=${java_options}" >> ${config_file}
fi
printf "backing up old configuration file to ${backup_filename}\n"
printf "${config_file} has been updated with new JAVA_OPTIONS of ${java_options}\n\n"

exit 0
