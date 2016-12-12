# Recipe name: stop_job_runner_all
#
# This will stop all job runner processes, including:
#  - stale worker monitor
#  - all resque workers
#  - Rails server
#  - Queue listener
#
# Note that if any of these processes was started manually
# or not using 'forever', then there is a chance that this recipe
# will not be able to kill that process.


# only run this recipe on Job Runner layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:job_runner_layer_name] rescue false


execute 'stop the stale worker monitoring script' do
  command %q{ps -e -o pid,command | grep [m]onitor_stale_workers.rb | sed 's/^[ \t]*//g' | cut -d ' ' -f 1 | xargs -L1 kill -9}
end

# stop all 'forever' processes
execute 'forever stopall' do
  command 'forever stopall'
end

execute 'force kill all workers' do
  command %q{ps -e -o pid,command | grep [r]esque-[0-9] | sed 's/^[ \t]*//g' | cut -d ' ' -f 1 | xargs -L1 kill -9}
end

execute 'kill rails' do
  command %q{ps -e -o pid,command | grep " [s]cript/rails " | sed 's/^[ \t]*//g' | cut -d ' ' -f 1 | xargs -L1 kill -s KILL}
end



