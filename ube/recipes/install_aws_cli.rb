# Recipe name: install_aws_cli
#
# installs the AWS CLI
# https://github.com/aws/aws-cli
#

package "python" do
  action :install
end

package "python-pip" do
  action :install
end

execute "install aws-cli using pip" do
  command "pip install awscli"
end
