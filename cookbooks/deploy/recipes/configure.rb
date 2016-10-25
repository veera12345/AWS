#
# Cookbook Name:: deploy
# Recipe:: configure
#

require 'time'

include_recipe 'git::clone_apps'

aws_opsworks_command = search("aws_opsworks_command").first
#2016-02-02T12:04:16+00:00
command_sent_at      = aws_opsworks_command["sent_at"]
t                    = Time.parse(command_sent_at)

search("aws_opsworks_app").each do |app|
  if app["deploy"] == false
    next
  end
  
  app_short_name = app["shortname"]
  repo_url = app["app_source"]["url"]
  release_path  = File.join("/", "data", app_short_name "release")
  release_timestamp = t.year.to_s.rjust(4, "0")+
    t.month.to_s.rjust(2, "0")+
    t.day.to_s.rjust(2, "0")+
    t.hour.to_s.rjust(2, "0")+
    t.min.to_s.rjust(2, "0")+
    t.sec.to_s.rjust(2, "0")
  
  releases = Dir.entries(release_path).select {
    |entry| File.directory? File.join(release_path,entry) and !(entry.start_with?(".")) 
  }
  
  if not releases.include?(release_timestamp)
    release_timestamp = a.sort_by(&:to_i)
  end
  
  app_path = File.join(release_path, release_timestamp)
  
  link 'Create current app symbolic link' do
    group                      "root"    #Integer, String
    # link_type                  Symbol      Default value: :symbolic
    mode                       "0664"        #Integer, String
    owner                      "root"        #Integer, String
    target_file                File.join("/", "etc", "nginx", "sites-enabled",   app_name+".conf")
    to                         File.join("/", "etc", "nginx", "sites-available", app_name+".conf")
    #action                     Symbol # defaults to :create if not specified
  end

include_recipe 'deploy::configure_global_environment_variables'


