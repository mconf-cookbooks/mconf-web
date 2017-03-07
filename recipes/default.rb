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

packages = node['mconf-web']['packages']['general']
packages.each do |pkg|
  package pkg do
    action :install
    options '--force-yes'
  end
end

# Make sure the user belongs to the app group, we need it to read some files
# that should be only visible to the app (e.g. certificates)
group node['mconf-web']['app_group'] do
  action :modify
  members node['mconf-web']['user']
  append true
end

# Create the app directory
# (Just the directory, capistrano does the rest)
directory node['mconf-web']['deploy_to'] do
  owner node['mconf-web']['user']
  group node['mconf-web']['app_group']
  mode '0755'
  recursive true
  action :create
end

# Ruby
include_recipe 'ruby_build'
include_recipe 'ruby_rbenv::system'
rbenv_global node['mconf-web']['ruby_version']

# Apache + Passenger + certificates
include_recipe "mconf-web::_apache_passenger"

# Custom certificates in the SSL store (if any)
include_recipe "mconf-web::_ssl_store"

# Monit
include_recipe "mconf-web::_monit"

# Logrotate
logrotate_app 'mconf-web' do
  cookbook 'logrotate'
  path ["#{node['mconf-web']['deploy_to_full']}/log/*.log"]
  options ['missingok', 'compress', 'copytruncate', 'notifempty', 'dateext']
  frequency node['mconf-web']['logrotate']['frequency']
  rotate node['mconf-web']['logrotate']['rotate']
  size node['mconf-web']['logrotate']['size']
  create "0600 #{node['mconf-web']['user']} #{node['mconf-web']['app_group']}"
  su "#{node['mconf-web']['user']} #{node['mconf-web']['app_group']}"
end
