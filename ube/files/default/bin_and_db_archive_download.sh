#!/bin/bash
#
# usage:  bin_and_db_archive_download.sh <build_number>
#
# Given the specified build number, this script will:
#   - attempt to download the zip archive from S3 that corresponds to the build #
#   - extract it into a build-specific directory off of the base_dir
#

set -x

printf "\n---- $0 ----\n\n"
s3cfg_file="/etc/s3cfg"
pwd=`pwd`
my_full_path="${pwd}/$0"
bin_dir="`dirname $0`"
base_dir="/mnt/ube_deployments"
if [ "$(uname)" == "Darwin" ]; then
    # Do something under Mac OS X platform
    base_dir="/tmp/migrations-$(date +%s)"
    mkdir -p ${base_dir}
    s3cfg_file=~/.s3cfg
fi
pushd "$base_dir" > /dev/null 2>&1

[[ -z "$1" ]] && echo "no build number specified on the command line" && exit 1
build_number="$1"

printf "Attempting to deploy build #${build_number}\n"

dist_dir="ube-db-${build_number}"
if [ -d ${dist_dir} ] ; then
    printf "WARNING:  The archive for build number #{build_number} may have already been downloaded and extracted.\n\n"
fi

archive_name="bin_and_db_migrations-${build_number}.zip"
if ( ! s3cmd --config=${s3cfg_file} info s3://shodogg-repository/ube-archives/${archive_name} ) ; then
    printf "No archive was found on S3 for build number $build_number\n\n"
    exit 1
fi

#  - make new dir for this version of the app
mkdir -p ${base_dir}/${dist_dir}
pushd ${base_dir}/${dist_dir} > /dev/null 2>&1

#  - download archive from S3 if necessary
destination_archive_path="${base_dir}/${dist_dir}/${archive_name}"
if [[ -f "${destination_archive_path}" ]]; then
    printf "The archive already exists. (${destination_archive_path}) It will not be downloaded again.\n\n"
else
    printf "Attempting to download build archive ${archive_name} from S3...\n\n"
    s3cmd --config=${s3cfg_file} --force get s3://shodogg-repository/ube-archives/${archive_name} "${destination_archive_path}"
fi
sleep 5s

timeout_in_seconds=40
start_time=$(date +%s)
while [ ! -f "${destination_archive_path}" ]; do
    current_time=$(date +%s)
    elapsed_time=$(( $current_time - $start_time ))
    printf "%5d seconds have elapsed and zip file not done downloading yet.\n" ${elapsed_time}
    if (( $elapsed_time > $timeout_in_seconds )); then
      echo "Timeout occurred after ${timeout_in_seconds} seconds."
      exit 1
    fi
    sleep 2s
done


#  - extract archive and copy files where they need to go
printf "Extracting build archive ${archive_name}\n"
unzip -uo ${archive_name}

popd > /dev/null 2>&1

popd > /dev/null 2>&1
