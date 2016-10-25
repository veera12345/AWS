#
# Cookbook Name:: users_and_groups
# Recipe:: create_groups
#

=begin
group 'name' do
  append                     TrueClass, FalseClass
  excluded_members           Array
  gid                        String, Integer
  group_name                 String # defaults to 'name' if not specified
  members                    Array
  non_unique                 TrueClass, FalseClass
  notifies                   # see description
  provider                   Chef::Provider::Group
  subscribes                 # see description
  system                     TrueClass, FalseClass
  action                     Symbol # defaults to :create if not specified
end

=end

group 'www-data' do
  #action :create
  action :modify
  members ['root', 'ubuntu']
  append true
end

group 'ubuntu' do
  #action :create
  action :modify
  members ['root', 'www-data']
  append true
end

group 'root' do
  #action :create
  action :modify
  members ['www-data', 'ubuntu']
  append true
end

group 'sudo' do
  action :modify
  members ['www-data', 'ubuntu']
  append true
end


