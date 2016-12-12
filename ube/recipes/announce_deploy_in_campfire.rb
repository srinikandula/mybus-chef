# Recipe name: announce_deploys
#
# This will announce the deployment in Campfire chat rooms
#

campfire_token = node[:ube][:campfire_token] rescue nil

if (campfire_token.to_s.strip.empty? rescue true)
  log "No campfire token was specified."
  return 1
end

build_number = node[:ube][:build_number] rescue 'Unspecified'
server_name = node[:opsworks][:instance][:hostname] rescue 'Unspecified Host'

json_message = %Q^{"message":{"body":"Build ##{build_number} deployed to #{server_name}"}}^

execute "announce deployment in the UBE chat room" do
  command %Q{curl -u #{campfire_token} -H 'Content-Type: application/json' -d '#{json_message}' https://shodogg.campfirenow.com/room/568407/speak.json}
end

execute "announce deployment in the general chat room" do
  command %Q{curl -u #{campfire_token} -H 'Content-Type: application/json' -d '#{json_message}' https://shodogg.campfirenow.com/room/552723/speak.json}
end

