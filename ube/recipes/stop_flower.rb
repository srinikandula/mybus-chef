# Recipe name: stop_flower
#
# This will stop flower on an instance that is part of the celery layer
#

# only run this recipe on a celery layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:celery_layer_name] rescue false

execute 'stop flower' do
  command "ps -e -o pid,command | grep -e '[p]ython.*flower' | sed 's/^\s*//g' | cut -d ' ' -f 1 | xargs -L1 kill -s TERM"
  timeout 600
end