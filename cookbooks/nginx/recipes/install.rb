#
# Cookbook Name:: nginx
# Recipe:: install
#

package 'nginx' do
  #allow_downgrade            TrueClass, FalseClass # Yum, RPM packages only
  #arch                       String, Array # Yum packages only
  #default_release            "stable"      #String # Apt packages only
  #flush_cache                Array
  #gem_binary                 String
  #homebrew_user              String, Integer # Homebrew packages only
  #notifies                   # see description
  #options                    String
  #package_name               "nginx"       #String, Array # defaults to 'name' if not specified
  #provider                   Chef::Provider::Package     # optional
  #response_file              String # Apt packages only
  #response_file_variables    Hash # Apt packages only
  #source                     String
  #subscribes                 # see description
  #timeout                    String, Integer
  #version                    String, Array
  action                     :install #Symbol # defaults to :install if not specified
end

service 'nginx' do
  action [ :enable, :start ]
end
