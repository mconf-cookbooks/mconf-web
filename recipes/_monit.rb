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

# Monit
include_recipe "monit-ng"
# temporary fix for https://bugs.launchpad.net/ubuntu/+source/monit/+bug/1786910
package 'Force monit 1:5.16-2' do
  package_name 'monit'
  version '1:5.16-2'
  options '--allow-downgrades'
end

# remove the old file first to prevent conflicts
file "#{node["monit"]["conf_dir"]}/mconf-web" do
  action :delete
end
monit_template = versioned_template("mconf-web.monitrc.erb", node['mconf-web']['version'])
template "#{node["monit"]["conf_dir"]}/mconf-web.conf" do
  source monit_template
  mode 00644
  owner "root"
  group "root"
  variables(
    deploy_to: node['mconf-web']['deploy_to_full'],
    rbenv_root: node['rbenv']['root_path'],
    num_workers: node['mconf-web']['resque']['workers']
  )
  notifies :restart, "service[monit]", :delayed
end
