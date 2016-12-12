#!/bin/bash
#
# usage:  copy_war_from_s3.sh <build_number>
#
# Given the specified build number, this script will:
#   - attempt to download the zip archive from S3 that corresponds to the build #
#   - extract it into a build-specific directory off of the base_dir
#
# note: please ensure JETTY_HOME is set, or else this script won't work.
#

set -ex

printf "\n---- $0 ----\n\n"
s3cfg_file="/etc/s3cfg"
pwd=`pwd`
my_full_path="${pwd}/$0"
bin_dir="`dirname $0`"
base_dir="/mnt/ube_deployments"
pushd "$base_dir" > /dev/null 2>&1

[[ -z "$1" ]] && echo "no build number specified on the command line" && exit 1
build_number="$1"

printf "Attempting to deploy build #${build_number}\n"

dist_dir="ube-${build_number}"
if [ -d ${dist_dir} ] ; then
    printf "Build number #{build_number} destination directory already exists.\n"
fi

archive_name="ube-${build_number}.zip"
if ( ! s3cmd --config=${s3cfg_file} info s3://shodogg-repository/ube-archives/${archive_name} ) ; then
    printf "No archive was found on S3 for build number $build_number\n\n"
    exit 1
fi

#  - make new dir for this version of the app
mkdir -p ${base_dir}/${dist_dir}
pushd ${base_dir}/${dist_dir} > /dev/null 2>&1

#  - download archive from S3
printf "Attempting to download build archive ${archive_name} from S3...\n\n"
if [ -f "${base_dir}/${dist_dir}/${archive_name}" ]; then
    printf "build archive already exists at ${base_dir}/${dist_dir}/${archive_name}.  skipping download.\n"
else
    s3cmd --config=${s3cfg_file} get s3://shodogg-repository/ube-archives/${archive_name} "${base_dir}/${dist_dir}/${archive_name}"
fi

#  - extract archive and copy files where they need to go
printf "Extracting build archive ${archive_name}\n"
unzip -o ${archive_name}
war_file=`find ${base_dir}/${dist_dir} -name ube-api*.war | head -1`
mv "$war_file" "${base_dir}/${dist_dir}/ube-${build_number}.war"

popd > /dev/null 2>&1

popd > /dev/null 2>&1

