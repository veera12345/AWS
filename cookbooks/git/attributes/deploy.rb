#
# Cookbook Name:: git
# Attribute:: deploy
#

case node[:platform]
when 'debian','ubuntu'
  default[:opsworks][:deploy_user][:group] = 'www-data'
when 'centos','redhat','fedora','amazon'
  default[:opsworks][:deploy_user][:group] = node['opsworks']['rails_stack']['name'] == 'nginx_unicorn' ? 'nginx' : 'apache'
end



default[:deploy] = {}
node[:deploy].each do |application, deploy|
  default[:deploy][application][:deploy_to] = "/var/www/#{application}"
  default[:deploy][application][:chef_provider] = node[:deploy][application][:chef_provider] ? node[:deploy][application][:chef_provider] : node[:opsworks][:deploy_chef_provider]
  unless valid_deploy_chef_providers.include?(node[:deploy][application][:chef_provider])
    raise "Invalid chef_provider '#{node[:deploy][application][:chef_provider]}' for app '#{application}'. Valid providers: #{valid_deploy_chef_providers.join(', ')}."
  end
  default[:deploy][application][:keep_releases] = node[:deploy][application][:keep_releases] ? node[:deploy][application][:keep_releases] : node[:opsworks][:deploy_keep_releases]
  default[:deploy][application][:current_path] = "#{node[:deploy][application][:deploy_to]}/current"
  default[:deploy][application][:document_root] = ''
  default[:deploy][application][:ignore_bundler_groups] = node[:opsworks][:rails][:ignore_bundler_groups]
  if deploy[:document_root]
    default[:deploy][application][:absolute_document_root] = "#{default[:deploy][application][:current_path]}/#{deploy[:document_root]}/"
  else
    default[:deploy][application][:absolute_document_root] = "#{default[:deploy][application][:current_path]}/"
  end


  default[:deploy][application][:user] = node[:opsworks][:deploy_user][:user]
  default[:deploy][application][:group] = node[:opsworks][:deploy_user][:group]
  default[:deploy][application][:shell] = node[:opsworks][:deploy_user][:shell]
  default[:deploy][application][:home] = if !node[:opsworks][:deploy_user][:home].nil?
                                           node[:opsworks][:deploy_user][:home]
                                         elsif self[:passwd] && self[:passwd][self[:deploy][application][:user]] && self[:passwd][self[:deploy][application][:user]][:dir]
                                           self[:passwd][self[:deploy][application][:user]][:dir]
                                         else
                                           "/home/#{self[:deploy][application][:user]}"
                                         end

  default[:deploy][application][:environment] = node[:deploy][application][:environment]
  default[:deploy][application][:environment_variables] = {}
  default[:deploy][application][:ssl_support] = node[:deploy][application][:ssl_support]

end
