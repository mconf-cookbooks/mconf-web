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

if node['mconf-web']['ssl']['letsencrypt']['enable']
  node.set['letsencrypt']['contact'] = node['mconf-web']['ssl']['letsencrypt']['contact']
  site = node['mconf-web']['domain']

  letsencrypt_certificate "#{site}" do
    crt      "/etc/apache2/ssl-tmp/#{site}.crt"
    key      "/etc/apache2/ssl-tmp/#{site}.key"
    chain    "/etc/apache2/ssl-tmp/#{site}.pem"
    method   "http"
    wwwroot  "/var/www/mconf-web/current/"
    notifies :restart, "service[apache2]"
    alt_names Array[ "www.#{site}" ]
  end
end
