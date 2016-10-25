#
# Cookbook Name:: deploy
# Recipe:: configure_global_environment_variables
#

aws_opsworks_apps            = search("aws_opsworks_app").first
aws_opsworks_rds_db_instance = search("aws_opsworks_rds_db_instance").first

app_env_hash = {}

aws_opsworks_apps.each do |app|
  app["data_sources"].each do |data_source|
  app_env_hash.update(app["environment"])
  app["data_sources"].each do |db|
    # each app can have multiple data_sources with different database_name, 
    # in our case, all applications in one stack use same rds and database, so overriding is not the issue
    # If in future this strategy changes, change the key name "DB_NAME" to "DB_NAME_"+app["shortname"].upcase(),
    # so that, the "DB_NAME" does not get overriden
    app_env_hash.update({"DB_NAME" => db["database_name"]})
  end
end

aws_opsworks_rds_db_instance.each do |rds|
  # There can be multiple db layers
  # in our case, there is only one RDS layer
  # In future if this strategy changes, append key names "DB_HOST", "DB_USER", "DB_PASS" with some unique string,
  # so that keys and their values doesn't get overriden
  # For example
  #    "DB_HOST_"+app["shortname"].upcase()
  #    "DB_USER_"+app["shortname"].upcase()
  #    "DB_PASS_"+app["shortname"].upcase()
  app_env_hash.update({"DB_HOST" => rds["address"]})
  app_env_hash.update({"DB_USER" => rds["db_user"]})
  app_env_hash.update({"DB_PASS" => rds["db_password"]})
end

template 'environment.erb' do
  source   'environment.erb'
  owner    'root'
  group    'root'
  mode     '0644'
  path     '/etc/environment'
  variables({
    :app_env_hash => app_env_hash
  })
  action :create
end
