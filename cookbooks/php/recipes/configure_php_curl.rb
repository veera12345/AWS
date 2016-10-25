#
# Cookbook Name:: php
# Recipe:: configure_php_curl
#


cookbook_file '/etc/php5/modes-available/curl.ini' do
  source 'curl.ini'
  owner 'root'
  group 'root'
  mode '0644'
  path '/etc/php5/modes-available/'
  action :create
end

link '/etc/php5/modes-available/20-curl.ini' do
  group                      "root"        #Integer, String
  mode                       "0664"        #Integer, String
  owner                      "root"        #Integer, String
  target_file                "/etc/php5/cli/conf.d/20-curl.ini"  #String # defaults to 'name' if not specified
  to                         "/etc/php5/modes-available/curl.ini"  #String
end

link '/etc/php5/modes-available/20-curl.ini' do
  group                      "root"        #Integer, String
  mode                       "0664"        #Integer, String
  owner                      "root"        #Integer, String
  target_file                "/etc/php5/fpm/conf.d/20-curl.ini"  #String # defaults to 'name' if not specified
  to                         "/etc/php5/modes-available/curl.ini"  #String
end

