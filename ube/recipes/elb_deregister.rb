# Recipe name: elb_deregister
#
# deregisters the instance from its ELB
#

# only run this recipe on a jetty layer or node.js layer
is_jetty = node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false
is_node_js = node[:opsworks][:instance][:layers].include? 'nodejs-app' rescue false
return unless is_jetty || is_node_js

aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]
jetty_elb_name = node[:ube][:elb][:java_load_balancer_name]
node_js_elb_name = node[:ube][:elb][:node_js_load_balancer_name]

if aws_access_key_token && aws_secret_key
  include_recipe 'aws'  # install right_aws gem for aws_elastic_lb

  are_elbs_the_same = is_jetty && is_node_js && jetty_elb_name == node_js_elb_name

  if is_jetty
    aws_elastic_lb "deregister jetty instance from ELB" do
      aws_access_key aws_access_key_token
      aws_secret_access_key aws_secret_key
      name jetty_elb_name
      action :deregister
    end    
  end
  
  if is_node_js && !are_elbs_the_same
    aws_elastic_lb "deregister node.js instance from ELB" do
      aws_access_key aws_access_key_token
      aws_secret_access_key aws_secret_key
      name node_js_elb_name
      action :deregister
    end    
  end

end