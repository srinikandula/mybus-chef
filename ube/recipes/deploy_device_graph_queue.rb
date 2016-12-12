# Recipe name: deploy_device_graph_queue
#
#

node.set[:ube][:dev_graph_app_name] = 'queue'

include_recipe 'ube::config_dev_graph_service'
include_recipe 'ube::deploy_device_graph_app'