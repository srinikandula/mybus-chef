# Recipe name: setup_celery
#
# This will install celery using pip3, as well as facebook and flower
#

# only run this recipe on a celery layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:celery_layer_name] rescue false

apt_package "python3-pip" do
  action :install
end


execute "install celery" do
  command "pip3 install celery"
end

execute "install requests" do
  command "pip3 install requests"
end

execute "install facebook" do
  command "pip3 install -e git+https://github.com/pythonforfacebook/facebook-sdk.git#egg=facebook-sdk"
end

execute "install google api client" do
  command "pip3 install --upgrade google-api-python-client"
end

execute "install flower" do
  command "pip3 install flower"
end