#
# Cookbook Name:: php
# Recipe:: install_php
#

bash "add-apt-repository ppa:ondrej/php5-5.6" do
  user "root"
end


# update repository
execute "apt-get update" do
  user "root"
end

# install python-software-properties
package "python-software-properties"

# update repository
execute "apt-get update" do
  user "root"
end

# install php 5.6
# package "php5" # Do not install php5, it installs all php5 related packages such as apache2
package "php5-dev"
package "php5-cli"

