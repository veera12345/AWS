#
# Cookbook Name:: php
# Recipe:: configure_php
#

cookbook_file '/etc/php5/cli/www.conf' do
  source 'www.conf'
  owner 'root'
  group 'root'
  mode '0644'
  path '/etc/php5/cli/'
  action :create
end
