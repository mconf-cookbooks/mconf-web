#
# Cookbook Name:: mconf-web
# Recipe:: default
# Author:: Leonardo Crauss Daronco (<daronco@mconf.org>)
#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

# Apache2 + Passenger
# Note: as of 2015.04.10, the cookbook passenger_apache2 still didn't support apache 2.4,
# so we can't use it in ubuntu 14.04 yet.
# The blocks below are mostly taken from that cookbook.

%W(apache2-prefork-dev libapr1-dev libcurl4-gnutls-dev apache2-mpm-worker).each do |pkg|
  package pkg do
    action :upgrade
  end
end

# Compile passenger's module for Apache
# Passenger is already installed via rbenv, so we have to run it in an rbenv-aware
# environment.

# First we need to find out where rbenv and passenger are
# Note: all this below because we don't know how to reliably generate the path where a
# gem is installed in a way that works for any version of ruby.
rbenv_env = [ %{export RBENV_ROOT="#{node['rbenv']['root_path']}"},
              %{export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"}
            ].join(' && ')
ruby_block "set rbenv ruby root" do
  block do
    rbenv_root = `#{rbenv_env} && rbenv prefix #{node['rbenv']['ruby']['version']}`
    node.override['rbenv']['ruby']['root_path'] = rbenv_root.strip
  end
  action :run
end
ruby_block "set gems root" do
  block do
    gem_root = `#{rbenv_env} && rbenv exec gem env | awk '/INSTALLATION DIRECTORY/ {print $4;}'`
    node.override['rbenv']['ruby']['gems_root'] = "#{gem_root.strip}/gems"
    node.override['passenger']['ruby_bin']      = "#{node['rbenv']['ruby']['root_path']}/bin/ruby"
    node.override['passenger']['root_path']     = "#{node['rbenv']['ruby']['gems_root']}/passenger-#{node['passenger']['version']}"
    node.override['passenger']['module_path']   = "#{node['passenger']['root_path']}/buildout/apache2/mod_passenger.so"
  end
  action :run
end

# Disable our configs to prevent errors in case we need to compile passenger
# Note: `apache_conf` with `enable false` doesn't work properly here
execute "disable #{node['mconf-web']['passenger']['conf_name']} apache config" do
  command "a2disconf #{node['mconf-web']['passenger']['conf_name']}"
  only_if { ::File.exists?("#{node['apache']['conf_dir']}/conf-enabled/#{node['mconf-web']['passenger']['conf_name']}.conf") }
end

rbenv_script 'passenger_module' do
  # Note: return always 0 because passenger's installer doesn't return 0 even on success
  code lazy { "if [ ! -f #{node['passenger']['module_path']} ]; then passenger-install-apache2-module _#{node['passenger']['version']}_ --auto --languages ruby; fi; exit 0;" }
  root_path     node['rbenv']['root_path']
  rbenv_version node['rbenv']['global']
end
ruby_block "check passenger module" do
  block { raise "Passenger module not found at #{node['passenger']['module_path']}!" }
  not_if { ::File.exists?(node['passenger']['module_path']) }
end

include_recipe 'apache2'
apache_module 'rewrite'
apache_module 'xsendfile'

%w{default default-ssl 000-default}.each do |site|
  apache_site site do
    enable false
  end
end

# Create passenger's conf file for Apache and enable it
apache_conf node['mconf-web']['passenger']['conf_name'] do
  enable true
end

include_recipe "mconf-web::_certificates"

# Apache website configuration
# Note: can't use web_app because it doesn't take variables
template "#{node['apache']['dir']}/sites-available/mconf-web.conf" do
  source "apache-site.conf.erb"
  mode 00644
  owner 'root'
  group 'root'
  variables node.run_state['mconf-web-certs']
  notifies :restart, "service[apache2]", :delayed
end
apache_site 'mconf-web' do
  action :enable
  notifies :restart, "service[apache2]", :delayed
end

# To validate our Apache configurations
execute 'validate apache' do
  command 'apache2ctl configtest'
end