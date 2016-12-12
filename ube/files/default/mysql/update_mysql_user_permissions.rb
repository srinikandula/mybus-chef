#!/usr/bin/env ruby
#
# Usage:
# update_mysql_user_permissions.rb <server_endpoint> <port> <root_user> <password>
#
# This script requires that you have the mysql client already installed.
# Version mysql-5.7.14-osx10.11-x86_64 is the only version tested with this script.



##############################################################################
#
#                  *** PERMISSION DEFINITIONS ***
#
#  Here are the permission definitions for each database.
#  Edit this section as necessary.
#  :select means the user will be READ-ONLY (i.e. SELECT privileges).
#  :all means the user will have ALL privileges.
#
##############################################################################

users = {
    :srini => {
        :all => %w(srini)
    },
    :srini_test => {
      :all => %w(srini)
    },
    :brian => {
        :all => %w(brian )
    },
    :brian_test => {
        :all => %w(brian )
    },
    :jason => {
        :all => %w(jason )
    },
    :jason_test => {
        :all => %w(jason )
    },
    :dev => {
        :select => %w(brian jason srini),
        :all => %w(sddev)
    },
    :mid_pilot_dev => {
        :select => %w(brian jason srini),
        :all => %w(midpilotdev sddev)
    },
    :demo => {
        :select => %w(brian jason srini),
        :all => %w(demo sddev)
    }
}

##############################################################################


server_endpoint = ARGV[0]
port = ARGV[1]
user = ARGV[2]
pwd = ARGV[3]

if `which mysql`.empty?
  puts "Error.  'mysql' was not found.  Please make sure mysql is installed.\n\n"
  exit 1
end

def usage
  puts "\nUsage:\n#{__FILE__} <server_endpoint> <port> <root_user> <password>.\n\n"
  exit 1
end

usage unless server_endpoint && port && user && pwd && ARGV.length == 4

database_names = users.keys;
sql_queries = {}
database_names.each { |d| sql_queries[d] = [] }

database_names.each do |db_name|
  [:select, :all].each do |privilege_type|
    unless users[db_name][privilege_type].nil?
        users[db_name][privilege_type].each do |username|
          priv_name = privilege_type == :all ? 'ALL' : 'SELECT'
          command = "GRANT #{priv_name} ON #{db_name}.* TO '#{username}'@'%';"
          command = "mysql -h#{server_endpoint} -u#{user} -p#{pwd} #{db_name} --execute=\"#{command}\""
          #puts "#{command}"
          result = `#{command}`
          puts "result: #{result}\n\n"
        end
    end
  end
end

