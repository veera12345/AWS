#
# Cookbook Name:: php
# Recipe:: install_php_composer
#

execute 'install_composer' do
  command                    "curl -sS https://getcomposer.org/installer | sudo php5 -- --install-dir=/usr/local/bin --filename=composer" # defaults to 'name' if not specified
  #creates                    String
  cwd                        "/tmp"
  #environment                Hash
  group                      "root"
  #notifies                   # see description
  #path                       Array
  #provider                   Chef::Provider::Execute
  #returns                    Integer, Array
  #sensitive                  TrueClass, FalseClass
  #subscribes                 # see description
  #timeout                    Integer, Float
  #umask                      String, Integer
  user                       "root"
  #action                     Symbol # defaults to :run if not specified
end
# curl -sS https://getcomposer.org/installer | sudo php5 -- --install-dir=/usr/local/bin --filename=composer
