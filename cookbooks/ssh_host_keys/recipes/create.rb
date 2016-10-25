#
# Cookbook Name:: ssh_host_keys
# Recipe:: create
#

applications = search("aws_opsworks_app")

hosts = {}
applications.each do |app|
  app_short_name     = app["shortname"]
  url                = app["app_source"]["url"].split("@")[1].split(":")[0]
  user               = app["app_source"]["url"].split("@")[0]
  repo_domain        = app["app_source"]["url"].split("@")[1].split(":")[0]
  repo_hostname      = app["app_source"]["url"].split("@")[1].split(":")[0].split(".")[0]
  identity_file_name = repo_hostname+"-"+app_short_name+"-deploy-private-key"
  identity_file_data = app["app_source"]["ssh_key"]
  if hosts.has_key?(repo_domain)
    hosts[repo_domain].push([url, identity_file_name, user])
  else
    hosts[repo_domain] = [[url, identity_file_name, user]]
  end
  
  template 'ssh_private_key.erb' do
    source   'ssh_private_key.erb'
    owner    'root'
    group    'root'
    mode     '0400'
    path     '/root/.ssh/'+identity_file_name
    variables({
      :ssh_key => identity_file_data
    })
    action :create
  end
  
end

template 'ssh_config.erb' do
  source   'ssh_config.erb'
  owner    'root'
  group    'root'
  mode     '0644'
  path     '/root/.ssh/config'
  variables({:hosts => hosts})
  action :create
end
