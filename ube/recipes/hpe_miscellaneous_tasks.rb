# Recipe name: hpe_miscellaneous_tasks
#
# A reciepe for doing miscellaneous tasks for HPE AWS deployment
#

is_jetty_layer = node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

if is_jetty_layer
  log "checking out git code in to '/mnt/HPSN-Library'"
  #command "git clone git@github.com:Shodogg/HPSN-Library.git /mnt/HPSN-Library"

  git "/mnt/HPSN-Library" do
    repository "git@github.com:Shodogg/HPSN-Library.git"
    reference "master"
    action :sync
  end


  #Download SAML keys from S3 bucket
  include_recipe 'aws'  # install right_aws gem for aws_s3_file
  ube = node[:ube]
  saml_key_file_location = '/home/jetty/'+ube[:hp_saml_pkcs12_file]

  log "SAML file location : #{saml_key_file_location}"
  #copy remote file on s3 to local directory
  aws_s3_file "#{saml_key_file_location}" do
    bucket "#{ube[:hp_keys_s3_bucket]}"
    remote_path "SAML_KEYS/#{ube[:hp_saml_pkcs12_file]}"
    aws_access_key_id "#{ube[:s3_access_key]}"
    aws_secret_access_key "#{ube[:s3_secret_key]}"
  end

end


package "s3cmd" do
  action :install
end

template "/etc/s3cfg" do
  source "s3cfg.erb"
  owner "root"
  group "root"
  mode "0644"
end
