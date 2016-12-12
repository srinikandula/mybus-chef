# Recipe name: deploy_device_graph_collection
#
#

node.set[:ube][:dev_graph_app_name] = 'collection'

include_recipe 'ube::config_dev_graph_service'
include_recipe 'ube::deploy_device_graph_app'