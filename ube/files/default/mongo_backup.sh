#!/bin/bash
#
# This script will perform a mongo dump of the local database into the
# ~/mongo_dumps directory and then also copy those files to a directory
# on a different ebs volume so that it gets backed up.
# The dump will be placed in a subdirectory
# named after the current date and time.
#

set -ex

mongo_backup_dir=/mnt/mongo_backups
backup_of_backup_dir=/vol/mongo-ebs/mongo_backups
sudo mkdir -p $mongo_backup_dir
sudo mkdir -p $backup_of_backup_dir
sudo chmod 777 $mongo_backup_dir
sudo chmod 777 $backup_of_backup_dir
pushd $mongo_backup_dir

output_dir=`date +%Y%m%d-%H%M`
mongodump --host localhost --port 27017 --out ./$output_dir
cp -a ./$output_dir $backup_of_backup_dir

popd


exit 0