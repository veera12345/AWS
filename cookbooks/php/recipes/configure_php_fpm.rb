#
# Cookbook Name:: php
# Recipe:: configure_php_fpm
#

cookbook_file '/etc/php5/fpm/www.conf' do
  source 'www.conf'
  owner 'root'
  group 'root'
  mode '0644'
  path '/etc/php5/fpm/'
  action :create
end

