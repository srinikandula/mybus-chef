# Recipe name: config_nginx
#
# This will create the nginx.conf file needed to configure nginx on the jetty layers
#


# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false


ports_to_redirect_to_https = [80];
subdomains_that_route_to_portal = node[:ube][:subdomains_that_route_to_portal] || []

log "subdomains_that_route_to_portal = #{subdomains_that_route_to_portal}"
log "node[:ube][:subdomains_that_route_to_portal] = #{node[:ube][:subdomains_that_route_to_portal]}"

configured_https_redirect_ports = node[:ube][:ports_to_redirect_to_https] rescue nil
if configured_https_redirect_ports && !configured_https_redirect_ports.empty?
  ports_to_redirect_to_https = configured_https_redirect_ports
end

template "/etc/nginx/nginx.conf" do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode '0644'
  variables({
    :ports_to_redirect_to_https => ports_to_redirect_to_https
  })
end