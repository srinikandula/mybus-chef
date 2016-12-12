# Recipe name: setup_kinesis_connector_config_files
#
# This will install all configuration files needed for the kinesis-redshift connector app
#

# only run this recipe on the analytics layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:analytics_layer_name] rescue false

ube = node[:ube]
analytics_props = node[:ube]['analytics']
ubuntu_user_home = ube[:ubuntu_home]
mongo_server_dns = (node[:opsworks][:layers][:mongo][:instances].first[1][:private_dns_name] rescue nil)
mongo_host_name = mongo_server_dns || ube[:mongo_host]
kinesis_user = 'ubuntu'

log "mongo host: #{mongo_host_name}"


include_recipe 'ube::config_ube_mongo_properties'

template "#{ubuntu_user_home}/.ube.analytics.properties" do
  source "ube.analytics.properties.erb"
  owner kinesis_user
  group kinesis_user
  mode "0640"
  variables({
                :app_name => analytics_props['appName'],
                :region_name => analytics_props['regionName'],
                :retry_limit => analytics_props['retryLimit'],
                :idle_time_between_reads => analytics_props['idleTimeBetweenReads'],
                :buffer_byte_size_limit => analytics_props['bufferByteSizeLimit'],
                :buffer_record_count_limit => analytics_props['bufferRecordCountLimit'],
                :buffer_milliseconds_limit => analytics_props['bufferMillisecondsLimit'],
                :redshift_endpoint => analytics_props['redshiftEndpoint'],
                :redshift_username => analytics_props['redshiftUsername'],
                :redshift_password => analytics_props['redshiftPassword'],
                :redshift_url => analytics_props['redshiftURL'],
                :redshift_data_delimiter => analytics_props['redshiftDataDelimiter'],
                :s3_bucket => analytics_props['s3Bucket'],
                :s3_endpoint => analytics_props['s3Endpoint'],
                :kinesis_input_stream => analytics_props['kinesisInputStream'],
                :connector_destination => analytics_props['connectorDestination'],
                :ube_analytics_enabled => analytics_props['ube_analytics_enabled'],
                :mid_analytics_enabled => analytics_props['mid_analytics_enabled'],
                :whitelist_tables_csv => analytics_props['whitelist_tables_csv'],

            })
end


template "#{ubuntu_user_home}/.aws.properties" do
  source "aws.properties.erb"
  owner kinesis_user
  group kinesis_user
  mode "0640"
end

include_recipe 'ube::setup_app_config_props'
