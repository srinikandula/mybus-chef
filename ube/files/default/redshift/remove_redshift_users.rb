#!/usr/bin/env ruby
#
# Usage:
# remove_redshift_users.sh <server_endpoint> <port> <root_user> <user1,user2,user3,...userN>
#
# This script requires that you have the psql client already installed.
# Version 8.4 is the only version tested with this script.

server_endpoint = ARGV[0]
port = ARGV[1]
root_user = ARGV[2]
users_to_delete_csv = ARGV[3]

if `which psql`.empty?
  puts "Error.  'psql' was not found.  Please make sure Postgres is installed.\n\n"
  exit 1
end

def usage
  puts "\nUsage:\n#{__FILE__} <server_endpoint> <port> <root_user> <user1,user2,user3,...userN>\n\n"
  exit 1
end

# validate correct command-line params
usage unless server_endpoint && port && root_user && users_to_delete_csv && ARGV.length == 4

# validate the user list string contains valid characters and is CSV format
unless users_to_delete_csv =~ /^([\w_]+,?)+$/
  puts "The list of users should not contain any spaces and should be comma-separated.
        The user names should contain only letters, numbers, or _.\n\n"
  exit 1
end

users_to_delete = users_to_delete_csv.split(',').select {|s| !s.to_s.strip.empty?}

puts "Deleting users: #{users_to_delete.inspect}\n"

query = users_to_delete.map {|user_name| "DROP USER IF EXISTS #{user_name};"}.join(' ')

cmd = %Q|psql -h #{server_endpoint} -U #{root_user} -d prod -p #{port} -c "#{query}"|
puts "command: #{cmd}\n"
result = `#{cmd}`
puts "result: #{result}\n\n"

