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

execute 'apt-get update'

include_recipe 'build-essential'

package 'git'
package 'libruby'
package 'aspell-en'
package 'libxml2-dev'
package 'libxslt1-dev'
package 'libmagickcore-dev'
package 'libmagickwand-dev'
package 'imagemagick'
package 'zlib1g-dev'
package 'libreadline-dev'
package 'libffi-dev'
package 'nfs-common'
package 'libcurl4-openssl-dev'
package 'openjdk-7-jre'
package 'redis-server'
package 'libapache2-mod-xsendfile'

deploy_to  = node['mconf-web']['deploy_to']
deploy_to += '/current' if node['mconf-web']['deploy_with_cap']


# Create the app directory
# (Just the directory, capistrano does the rest)

directory deploy_to do
  owner node['mconf']['user']
  group node['mconf']['app_group']
  mode '0755'
  recursive true
  action :create
end


# Ruby
include_recipe 'ruby_build'
include_recipe 'rbenv::user'

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
# Note: passenger is already installed via rbenv, so we have to run it in an
# rbenv-aware environment
rbenv_script 'passenger_module' do
  code          "passenger-install-apache2-module _#{node['passenger']['version']}_ --auto"
  rbenv_version node['rbenv']['global']
  user          node['mconf']['user']
  group         node['mconf']['app_group']
  cwd           node['mconf-web']['deploy_to_full']
  only_if { node['passenger']['install_module'] }
  not_if { ::File.exist?(node['passenger']['module_path']) }
end

include_recipe 'apache2'
apache_module 'rewrite'

%w{default default-ssl 000-default}.each do |site|
  apache_site site do
    enable false
  end
end

# Create passenger's conf file for Apache and enable it
apache_conf 'mconf-passenger' do
  enable true
end

if node['mconf-web']['ssl']['enable']
  cert_file = node['mconf-web']['ssl']['certificates']['file']
  cert_path = "/etc/ssl/certs/#{cert_file}"
  cookbook_file cert_path do
    source cert_file
    owner 'root'
    group 'root'
    mode 00644
    action :create
  end

  cert_key_file = node['mconf-web']['ssl']['certificates']['key']
  cert_key_path = "/etc/ssl/private/#{cert_key_file}"
  cookbook_file cert_key_path do
    source cert_key_file
    owner 'root'
    group 'root'
    mode 00600
    action :create
  end
else
  cert_path = ''
  cert_key_path = ''
end

# Apache website configuration
web_app 'mconf-web' do
  template 'apache-site.conf.erb'
  variables({
    cert_file: cert_path,
    cert_key_file: cert_key_path,
  })
end


# Monit

package "monit"
service "monit"

template "/etc/monit/conf.d/mconf-web" do
  source "monit-config.erb"
  mode 00644
  owner "root"
  group "root"
  notifies :restart, "service[monit]", :delayed
end

template "/etc/monit/monitrc" do
  source "monitrc.erb"
  mode 00600
  owner "root"
  group "root"
  notifies :restart, "service[monit]", :delayed
end


# Logrotate
logrotate_app 'mconf-web' do
  cookbook 'logrotate'
  path [ "#{deploy_to}/log/production.log", "#{deploy_to}/log/resque_*.log" ]
  options [ 'missingok', 'compress', 'copytruncate', 'notifempty' ]
  frequency 'daily'
  rotate 10
  size '50M'
  create '644 mconf www-data'
end
