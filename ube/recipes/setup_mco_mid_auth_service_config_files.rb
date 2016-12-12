# Recipe name: setup_mco_mid_auth_service_config_files
#
# This will create/update the .ube_portal_socket_config.js file used by the node.js server
#
# Expected custom JSON format for the node is as follows.  Everything is optional.
#
# "mco_mid_auth_service" : {
#    "web": {
#        "port": <port #>,
#    },
#    "ssl": {
#        "enabled": true/false,
#        "privateKeyFilename": "/path/to/pk/ssl_pk.key",
#        "certificateFilename":
#    },
#    "key_pairs": [
#        {
#            "publicKey": "<pubKey1>",
#            "privateKey": "<privateKey1>"
#        },
#        {
#            "publicKey": "<pubKey2>",
#            "privateKey": "<privateKey2>"
#        }
#     ],

# }
#


# only run this recipe on a mco-mid auth service layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mco_mid_auth_service_layer_name] rescue false

auth_service = node[:mco_mid_auth_service]


template "/etc/.mid_auth_config.js" do
  source "mco_mid_auth_service_config.js.erb"
  owner "root"
  group "root"
  mode "0644"
  variables({:cfg => auth_service})
end