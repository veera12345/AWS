#
# Cookbook Name:: git
# Recipe:: clone_apps

include_recipe 'ssh_host_keys::create'

require 'time'

aws_opsworks_command = search("aws_opsworks_command").first
#2016-02-02T12:04:16+00:00
command_sent_at      = aws_opsworks_command["sent_at"]
t                    = Time.parse(command_sent_at)

search("aws_opsworks_app").each do |app|
  if app["deploy"] == false or app["type"].downcase() != "git"
    next
  end
  
  app_short_name = app["shortname"]
  repo_url = app["app_source"]["url"]
  release_path = File.join("/", "data", app_short_name "release", 
    t.year.to_s.rjust(4, "0")+
    t.month.to_s.rjust(2, "0")+
    t.day.to_s.rjust(2, "0")+
    t.hour.to_s.rjust(2, "0")+
    t.min.to_s.rjust(2, "0")+
    t.sec.to_s.rjust(2, "0")
  )
  
  directory 'create app release directory' do
    path         release_path
    recursive    true     #  For the owner, group, and mode properties, recursive applies only to the leaf directory
    owner        'www-data'
    group        'sudo'
    mode         '0777'
    action       :create
  end
  
  execute "Clone repository" do
    command    "git clone "+repo_url+" "+release_path
    cwd        release_path
    #ignore_failure true
  end
end

