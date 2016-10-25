#
# Cookbook Name:: git
# Recipe:: checkout
#

aws_opsworks_command = search("aws_opsworks_command").first

search("aws_opsworks_app").each do |app|
  
  if app["deploy"] == false and 
    next
  end
  
  if 
  else
    branch = app["revision"]
  
  if app["type"].downcase() != "git" or branch == nil or branch == "null"
    next
  end
  
  execute "Checkout to branch" do
    command "git checkout "+branch
    cwd File.join("/var/www", app["name"])
    #ignore_failure true
  end
end

