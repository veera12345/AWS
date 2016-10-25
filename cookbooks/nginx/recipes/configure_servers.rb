#
# Cookbook Name:: nginx
# Recipe:: configure_servers
#


#has_template?(tmpl, cookbook = nil) ⇒ String?
include Chef::ChefHelpers::HasSource

aws_opsworks_elastic_load_balancer = search("aws_opsworks_elastic_load_balancer").first
aws_opsworks_command  = search("aws_opsworks_command").first

search("aws_opsworks_app").each do |app|
  app_name = app["name"]
  template_path = File.join("sites-available", app_name+"conf.erb"
  if aws_opsworks_command["type"] == "deploy"
    if app["deploy"] == false
      next
    end
  end
  
  if not has_template?(template_path))
    template_path = File.join("sites-available", "default_app.conf.erb")
  end
  
  domain_names    = app["domains"]
  # temp change, for testing: Add appname.elb_endpoint in domains
  domain_names.push(app_name+"."+aws_opsworks_elastic_load_balancer["dns_name"])
  app_root_dir    = File.join("/data", app_name, "current")
  
  template 'Available site configuration for app' do
    source template_path
    owner 'root'
    group 'root'
    mode '0644'
    path  File.join("/etc", "nginx", "sites-available", app_name+".conf")
    variables({
      :app_name => app_name,
      :domain_names => domain_names,
      :app_root_dir => app_root_dir
    })
    action :create
  end
  
  link 'Create site-enabled symbolic link' do
    group                      "root"    #Integer, String
    # link_type                  Symbol      Default value: :symbolic
    mode                       "0664"        #Integer, String
    owner                      "root"        #Integer, String
    target_file                File.join("/etc", "nginx", "sites-enabled", app_name+".conf")
    to                         File.join("/etc", "nginx", "sites-available", app_name+".conf")
    #action                     Symbol # defaults to :create if not specified
  end
  
end




