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
