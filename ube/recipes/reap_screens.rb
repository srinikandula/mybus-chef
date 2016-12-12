# Recipe name: reap_screens
#
# This will trigger the java server to run the screen/session reaper task
# in order to inactivate expired screens, sessions, events, etc.
#

configured_base_url = node[:ube][:api_base_url] rescue nil
configured_base_url = nil if configured_base_url.to_s.strip.empty?

reaper_url = "#{configured_base_url}/api/screenSession/reap/0500c3743ffd11e391eace3f5508acd9"

log "reaper_url is #{reaper_url}"

execute "invoke screen reaper task" do
  command "/usr/bin/curl -X POST --verbose #{reaper_url}"
end
