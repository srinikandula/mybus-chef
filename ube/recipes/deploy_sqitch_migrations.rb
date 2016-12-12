# Recipe name: deploy_sqitch_migrations
#
# This recipe will download the db migrations code and the bin/scripts code for the
# specified build number.  It then extracts the archives and runs sqitch migrations on to
# a database configured in the stack settings

include_recipe 'ube::install_configure_sqitch'

ube_deployments_dir = node[:ube]['deployments_dir']
engine = node[:sqitch][:engine]
registry = node[:sqitch][:registry]
user = node[:sqitch][:user]
pwd = node[:sqitch][:pwd]
host = node[:sqitch][:host]
port = node[:sqitch][:port]
database = node[:sqitch][:database]
change = node[:sqitch][:change]

#db:mysql://user:'pwd'@host:port/db
dburi = "db:mysql://#{user}:'#{pwd}'@#{host}:#{port}/#{database}"

Chef::Log.info("downloaded the scripts, will use dburi : #{dburi}")
log "sqitch  : : \n#{node[:sqitch].inspect}\n\n"

#If you intend to specify a change to be deployed please pass it's name as custom JSON in execute recipe screen
#please read the documentation on https://shodogg.atlassian.net/wiki/pages/editpage.action?pageId=72548354
if change.to_s.strip.length == 0
  command = "sqitch --engine #{engine} --registry #{registry} deploy #{dburi}"
else
  command = "sqitch --engine #{engine} --registry #{registry} deploy #{dburi} --to #{change}"
end

Chef::Log.info("Running command  : #{command}")

execute "run sqitch deploy" do
  cwd "#{ube_deployments_dir}/ube-db-#{node[:ube]['build_number']}/db/migrations/sqitch_migrations/"
  command "#{command}"
end

Chef::Log.info("Completed sqitch deployment")
