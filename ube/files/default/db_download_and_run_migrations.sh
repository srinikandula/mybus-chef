#!/bin/bash
#
# usage:  db_download_and_run_migrations.sh <build_number>
#
# Given the specified build number, this script will:
#   - attempt to download the zip archive from S3 that corresponds to the build #
#   - extract it into a build-specific directory off of the base_dir
#   - run the script to execute mongo migrations
#

set -ex

printf "\n---- $0 ----\n\n"
s3cfg_file="/etc/s3cfg"
pwd=`pwd`
my_full_path="${pwd}/$0"
bin_dir="`dirname $0`"
base_dir="/mnt/ube_deployments"
if [ "$(uname)" == "Darwin" ]; then
    # Do something under Mac OS X platform
    base_dir="/tmp/migrations-$(date +%s)"
    mkdir -p $base_dir
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

#  - download archive from S3
printf "Attempting to download build archive ${archive_name} from S3...\n\n"
s3cmd --config=${s3cfg_file} --force get s3://shodogg-repository/ube-archives/${archive_name} "${base_dir}/${dist_dir}/${archive_name}"

#  - extract archive and copy files where they need to go
printf "Extracting build archive #{archive_name}\n"
unzip -uo ${archive_name}

# jason::new-host-7 { /tmp/dbmigrations/bin/mongo_migrate }-> ./mongo_migrate
# Usage: mongo_migrate [options] [params]
        # -g       generate
        # -r       run
        # -t       target (up or down)
        # -f       migration_file|migration_name
        # -c       configuration file
printf "PWD is $PWD\n"
printf "specifying config file: ${base_dir}/${dist_dir}/bin/mongo_migrate/config.cfg"
bash ./bin/mongo_migrate/mongo_migrate -c ${base_dir}/${dist_dir}/bin/mongo_migrate/config.cfg -rt up

popd > /dev/null 2>&1

popd > /dev/null 2>&1

exit 0
