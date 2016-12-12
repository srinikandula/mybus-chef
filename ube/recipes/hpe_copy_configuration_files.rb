# Recipe name: hpe_ube_configuration_files
#
# This will copy the keys needed for SAML authentication on a layer running the ube
#

# only run this recipe on a jetty layer
is_jetty_layer = node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

return unless is_jetty_layer

include_recipe 'aws'  # install right_aws gem for aws_s3_file

ube = node[:ube]
jetty_user_home = node[:ube][:jetty_user_home]
saml_key_file_location = #{jetty_user_home}/node[:ube][:hp_saml_pkcs12_file]

log "SAML file location : #{saml_key_file_location}"
#copy remote file on s3 to local directory
aws_s3_file "#{saml_key_file}" do
  action :create_if_missing
  bucket "#{ube['s3_deployment_archives_bucket']}"
  remote_path "#{social_celery_archive_s3_path}"
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end
