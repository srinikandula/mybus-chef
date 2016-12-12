#!/usr/bin/env ruby
#
# Usage:
# update_redshift_user_permissions.rb <server_endpoint> <port> <root_user>
#
# This script requires that you have the psql client already installed.
# Version 8.4 is the only version tested with this script.



##############################################################################
#
#                  *** PERMISSION DEFINITIONS ***
#
#  Here are the permission definitions for each server.
#  Edit this section as necessary.
#  :select means the user will be READ-ONLY (i.e. SELECT privileges).
#  :all means the user will have ALL privileges.
#
##############################################################################

users = {
    :dev => {

        :select => %w(jaspersoft sd_dev),
        :all => %w(srini brian sd_dev cogniance_dev)
    },
    :staging => {
        :select => %w(jaspersoft brian),
        :all => %w(srini sd_staging cogniance_staging)
    },
    :prod => {
        :select => %w(jaspersoft brian),
        :all => %w(srini sd_prod)
    },
    :mid_demo => {
        :select => %w(jaspersoft srini cogniance_dev cogniance_staging),
        :all => %w(srini brian sd_dev)
    }
}

##############################################################################


server_endpoint = ARGV[0]
port = ARGV[1]
user = ARGV[2]

if `which psql`.empty?
  puts "Error.  'psql' was not found.  Please make sure Postgres is installed.\n\n"
  exit 1
end

def usage
  puts "\nUsage:\n#{__FILE__} <server_endpoint> <port> <root_user>\n\n"
  exit 1
end

usage unless server_endpoint && port && user && ARGV.length == 3

database_names = users.keys;
sql_queries = {}
database_names.each { |d| sql_queries[d] = [] }

database_names.each do |db_name|
  [:select, :all].each do |privilege_type|
    users[db_name][privilege_type].each do |username|
      priv_name = privilege_type == :all ? 'ALL' : 'SELECT'
      sql_queries[db_name] << "GRANT #{priv_name} ON ALL TABLES IN SCHEMA public TO #{username};"
    end
  end
  query = sql_queries[db_name].join(" ")
  # query = "SET search_path TO public; select count(*) from analytics_feed; select count(*) from screen_session_summary"
  cmd = %Q|psql -h #{server_endpoint} -U #{user} -d #{db_name} -p #{port} -c "#{query}"|
  puts "command: #{cmd}\n"
  result = `#{cmd}`
  puts "result: #{result}\n\n"
end

