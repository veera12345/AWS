#
# Cookbook Name:: deploy
# Recipe:: default
#

require 'time'
require 'yaml'

include_recipe 'git::clone_apps'
include_recipe 'deploy::configure_global_environment_variables'

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
  current_path  = File.join("/", "data", app_short_name, "current")
  
  releases = Dir.entries(release_path).select {
    |entry| File.directory? File.join(release_path,entry) and !(entry.start_with?(".")) 
  }
  releases = releases.sort_by(&:to_i)
  
  #active_app_timestamp = File.readlink("/", "data", app_short_name, "current")
  active_app_timestamp = File.realpath(current_path).split("/")[-1]
  
  # if this recipe is running under setup lifecycle, there won't any active application
  if not releases.include?(active_app_timestamp)
    active_app_timestamp = releases[-1]
    # Note : if there are no previous releases, active_app_timestamp will be the latest release
    # Caution : In autoscaling, take care of such conditions because, previous releases might be 
    #           present in some nodes (oldest), and at the same time, the new nodes might not have the 
    # previous releases. To avoid such problem, add code here that will fetch the older release from some
    # older deployment tracker system (e.g. put the deployment release in S3 bucket and fetch it when not present)
  end
  
  active_app_path = File.join(release_path, active_app_timestamp)
  active_app_appspec = YAML.load_file(File.join(active_app_path , "appspec.yml"))
  
  if active_app_appspec.has_key?("hooks")
    if active_app_appspec["hooks"].has_key?("ApplicationStop")
      active_app_appspec["hooks"]["ApplicationStop"].each do |command_parameters|
        if command_parameters.has_key("runas")
          runas = command_parameters["runas"]
        else
          runas = "root"
        end
        
        application_stop_command = command_parameters["location"]
        if application_stop_command.start_with?("/")
          application_stop_command = application_stop_command
        elsif application_stop_command.start_with?("~/")
          if runas == "root"
            application_stop_command = File.join("/", "root", application_stop_command[2..-1])
          else
            application_stop_command = File.join("/", "home", runas, application_stop_command[2..-1])
          end
        else
          application_stop_command = File.join(active_app_path, application_stop_command)
        end
        execute "ApplicationStop" do
          command           application_stop_command
          cwd               active_app_path
          user              runas
          #environment       {
          #  "APPLICATION_NAME" => '',
          #  "DEPLOYMENT_ID" => '',
          #  "DEPLOYMENT_GROUP_NAME" => '',
          #  "DEPLOYMENT_GROUP_ID" => '',
          #  "LIFECYCLE_EVENT" => ''
          #}
          ignore_failure    true
        end
      end
    end
  end
  
  release_timestamp = t.year.to_s.rjust(4, "0")+
    t.month.to_s.rjust(2, "0")+
    t.day.to_s.rjust(2, "0")+
    t.hour.to_s.rjust(2, "0")+
    t.min.to_s.rjust(2, "0")+
    t.sec.to_s.rjust(2, "0")
  
  
  # if this recipe is running under cofiguration or setup lifecycle, command sent_at will not match the latest release,
  # which means sent_at will not match the latest git clone
  if not releases.include?(release_timestamp)
    release_timestamp = releases[-1]
  end
  
  
  # Now check if we are installing for undeploy, set the release_app_path for one step previous clone timestamp,
  # otherwise we are already at the latest release timestamp hence no need to change
  if aws_opsworks_command["type"] == "undeploy" or aws_opsworks_command["type"] == "rollback"
    active_app_timestamp_index = releases.find_index(active_app_timestamp)
    release_timestamp = releases[active_app_timestamp_index-1]
    # Note    : if there are no previous releases, release_app_path will be the latest release
  end
  
  release_app_path = File.join(release_path, release_timestamp)
  release_app_appspec = YAML.load_file(File.join(active_app_path , "appspec.yml"))
  
  
  
  if release_app_appspec.has_key?("hooks")
    if release_app_appspec["hooks"].has_key?("BeforeInstall")
      release_app_appspec["hooks"]["BeforeInstall"].each do |command_parameters|
        if command_parameters.has_key("runas")
          runas = command_parameters["runas"]
        else
          runas = "root"
        end
        
        before_install_command = command_parameters["location"]
        if before_install_command.start_with?("/")
          before_install_command = before_install_command
        elsif before_install_command.start_with?("~/")
          if runas == "root"
            before_install_command = File.join("/", "root", before_install_command[2..-1])
          else
            before_install_command = File.join("/", "home", runas, before_install_command[2..-1])
          end
        else
          before_install_command = File.join(release_app_path, before_install_command)
        end
        
        execute "BeforeInstall" do
          command           before_install_command
          cwd               release_app_path
          user              runas
          ignore_failure    true
        end
      end
    end
  end
  
  # Now, time to do installation, i.e. place files in proper locations
  if release_app_appspec.has_key?("files")
    release_app_appspec["files"].each do |move_path|
      if move_path.has_key?("source") and move_path.has_key?("destination")
        source_path      = move_path["source"]
        destination_path = move_path["destination"]
        if source_path.start_with?("/")
          source_path = File.join("file://", source_path[1..-1])
        elsif source_path.start_with?("~/")
          source_path = File.join("file:///", "root", source_path[2..-1])
        else
          source_path = File.join("file:///", release_app_path[1..-1], source_path)
        end
        if destination_path.start_with?("/")
          destination_path = File.join("file://", destination_path[1..-1])
        elsif destination_path.start_with?("~/")
          destination_path = File.join("file:///", "root", destination_path[2..-1])
        else
          destination_path = File.join("file:///", release_app_path[1..-1], destination_path)
        end
        
        
        remote_file "Copy/Move file" do 
          path         destination_path
          source       source_path
          owner        'root'
          group        'root'
          mode         0755
        end
        
      end
    end
  end
  
  # Now, set proper file permissions
  if release_app_appspec.has_key?("permissions")
    release_app_appspec["permissions"].each do |permissions|
      if permissions.has_key?("object")
        object_path      = permissions["object"]
        
        #pattern
        #except
        
        #owner
        if permissions.has_key?("owner")
          object_owner = permissions["owner"]
        else 
          object_owner = "root"
        end
        
        #group
        if permissions.has_key?("group")
          object_group = permissions["group"]
        else 
          object_group = "root"
        end
        
        #mode
        if permissions.has_key?("mode")
          object_mode      = permissions["mode"]
        else
          object_mode      = "4755"
        end
        
        #acls
        #context
        if permissions.has_key?("type")
          object_type = permissions["type"]
        else
          object_type = "file"
        end
        
        if object_path.start_with?("/")
          object_path = object_path
        elsif object_path.start_with?("~/")
          object_path = File.join("/", "root", object_path[2..-1])
        else
          object_path = File.join(release_app_path, object_path)
        end
        
        if type == "directory"
          directory 'Release directories permissions' do
            path          object_path
            owner         object_owner
            group         object_group
            mode          object_mode
            action        :create
          end
        else
          file 'Release files permissions' do
            path          object_path
            mode          object_mode
            owner         object_owner
            group         object_group
            action        :create
          end
        end
        
        
        
      end
    end
  end
  
  
  # now create symbolic links, New custum feature, not available in AWS codedeploy
  if release_app_appspec.has_key?("symlinks")
    release_app_appspec["symlinks"].each do |link_path|
      if link_path.has_key?("location") and link_path.has_key?("to")
        link_location      = link_path["location"]
        link_to            = link_path["to"]
        if link_location.start_with?("/")
          link_location = link_location
        elsif link_location.start_with?("~/")
          link_location = File.join("/", "root", link_location)
        else
          link_location = File.join(release_app_path, link_location)
        end
        if link_to.start_with?("/")
          link_to = link_to
        elsif link_to.start_with?("~/")
          link_to = File.join("/", "root", link_to[2..-1])
        else
          link_to = File.join(release_app_path[1..-1], link_to)
        end
        
        if link_path.has_key?("mode")
          link_mode = link_path["mode"]
        else
          link_mode = "4755"
        end
        
        if link_path.has_key?("owner")
          link_owner = link_path["owner"]
        else
          link_owner = "root"
        end
        
        if link_path.has_key?("group")
          link_ = link_path["group"]
        else
          link_group = "root"
        end
        
        #if link_path.has_key?("")
        #  link_ = link_path[""]
        #else
        #  link_ = ""
        #end
        
        
        link 'Create symbolic links' do
          group                      link_group
          link_type                  :symbolic
          mode                       link_mode
          owner                      link_owner
          target_file                link_location
          to                         link_to
          action                     :create
        end
        
        
      end
    end
  end
  
  
  
  # Now set the release app as current active app
  link 'Create current app symbolic link' do
    group                      "root"
    link_type                  :symbolic
    mode                       "0664"
    owner                      "root"
    target_file                current_path
    to                         release_app_path
    action                     :create
  end
  
  
  
  # Now run AfterInstall deployment lifecycles
  if release_app_appspec.has_key?("hooks")
    if release_app_appspec["hooks"].has_key?("AfterInstall")
      release_app_appspec["hooks"]["AfterInstall"].each do |command_parameters|
        if command_parameters.has_key("runas")
          runas = command_parameters["runas"]
        else
          runas = "root"
        end
        
        after_install_command = command_parameters["location"]
        if after_install_command.start_with?("/")
          after_install_command = after_install_command
        elsif after_install_command.start_with?("~/")
          if runas == "root"
            after_install_command = File.join("/", "root", after_install_command[2..-1])
          else
            after_install_command = File.join("/", "home", runas, after_install_command[2..-1])
          end
        else
          after_install_command = File.join(release_app_path, after_install_command)
        end
        
        execute "AfterInstall" do
          command           after_install_command
          cwd               release_app_path
          user              runas
          ignore_failure    true
        end
      end
    end
  end
  
  
  
  
  
  
  
  
  
  
  



