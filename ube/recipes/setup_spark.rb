# Recipe name: setup_spark
#
# This will install and configure apache spark
#
# only run this recipe on a spark layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:spark_layer_name] rescue false

include_recipe 'aws'  # install right_aws gem for aws_s3_file

spark_tarball = 'spark-1.6.1-bin-hadoop1-scala2.11.tgz'
spark_user = 'spark'
spark_user_home = "/home/#{spark_user}"
spark_install_base_dir ="#{spark_user_home}/spark-1.6.1"
download_destination = "#{spark_user_home}/#{spark_tarball}"

aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]

user spark_user do
  home spark_user_home
  shell '/bin/bash'
  action :create
  system true
end


# download build archive
aws_s3_file download_destination do
  action :create_if_missing
  bucket 'shodogg-repository'
  remote_path spark_tarball
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end


execute 'unzip Spark tarball' do
  cwd spark_user_home
  command "tar xvzf #{spark_tarball} -C #{spark_install_base_dir}"
  only_if { ::Dir["#{spark_install_base_dir}/*"].empty? }
end

