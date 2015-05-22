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

%w{git libruby aspell-en libxml2-dev libxslt1-dev libmagickcore-dev libmagickwand-dev imagemagick
   zlib1g-dev libreadline-dev libffi-dev nfs-common libcurl4-openssl-dev openjdk-7-jre redis-server
   libapache2-mod-xsendfile}.each do |pkg|
  package pkg
end

deploy_to  = node['mconf-web']['deploy_to']
deploy_to += '/current' if node['mconf-web']['deploy_with_cap']

# Make sure the user belongs to the app group, we need it to read some files
# that should be only visible to the app (e.g. certificates)
group node['mconf']['app_group'] do
  action :modify
  members node['mconf']['user']
  append true
end

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
include_recipe 'rbenv::system'

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
rbenv_script 'passenger_module' do
  code          "passenger-install-apache2-module _#{node['passenger']['version']}_ --auto; [ -f #{node['passenger']['module_path']} ]"
  root_path     node['rbenv']['root_path']
  rbenv_version node['rbenv']['global']
  creates       node['passenger']['module_path']
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
apache_conf 'mconf-passenger' do
  enable true
end

certs = {
  certificate_file: nil,
  certificate_key_file: nil,
  ca_certificate_file: nil,
  certificate_chain_file: nil
}
if node['mconf-web']['ssl']['enable']
  node.override['mconf-web']['http_protocol'] =
    node['mconf-web']['ssl']['enable'] ? 'https' : 'http'

  apache_module 'socache_shmcb'
  apache_module 'ssl'

  certs.each do |cert_name, value|
    if node['mconf-web']['ssl']['certificates'].key?(cert_name)
      file = node['mconf-web']['ssl']['certificates'][cert_name]
      path = "/etc/apache2/ssl/#{file}"

      cookbook_file path do
        source file
        owner 'root'
        group node['mconf']['app_group']
        mode 00640
        action :create
      end

      certs[cert_name] = path
    end
  end
end

# Shibboleth
if node['mconf-web']['ssl']['enable'] && node['mconf-web']['shibboleth']['enable']

  package 'libapache2-mod-shib2'

  apache_module 'shib2' do
    identifier 'mod_shib'
  end

  federation = node['mconf-web']['shibboleth']['federation']

  ['attribute-map.xml', 'attribute-policy.xml', 'shibboleth2.xml'].each do |template|
    template "/etc/shibboleth/#{template}" do
      source "#{federation}-#{template}.erb"
      mode 00644
      owner "root"
      group "root"
      variables(
        domain: node['mconf-web']['domain'],
        certificate_file: File.basename(node['mconf-web']['shibboleth']['certificates']['certificate_file']),
        certificate_key_file: File.basename(node['mconf-web']['shibboleth']['certificates']['certificate_key_file'])
      )
      notifies :restart, "service[apache2]", :delayed
    end
  end

  # Generate certificates if requested to.
  # shib_keygen will only generate if the certificate files do not exist.
  execute 'generate_shib_certificates' do
    command "shib-keygen -y 3 -h #{node['mconf-web']['domain']} -e https://#{node['mconf-web']['domain']}/shibboleth -u _shibd -g _shibd; [ -f /etc/shibboleth/sp-cert.pem ]"
    creates "/etc/shibboleth/sp-key.pem"
    notifies :restart, "service[apache2]", :delayed
    only_if { node['mconf-web']['shibboleth']['certificates']['create'] }
  end

  ruby_block "collect shib certificate content" do
    block do
      output = IO.read(node['mconf-web']['shibboleth']['certificates']['certificate_file'])
      output.gsub!(/.*BEGIN CERTIFICATE.*\n/, '')
      output.gsub!(/\n.*END CERTIFICATE.*$/, '')
      output.strip!
      node.override['mconf-web']['shibboleth']['certificates']['certificate_content'] = output
    end
  end

  template '/root/metadata-sp.xml' do
    source "#{federation}-metadata-sp.xml.erb"
    mode 00600
    owner 'root'
    group 'root'
    variables(
      domain: node['mconf-web']['domain'],
      institution: node['mconf-web']['shibboleth']['institution'],
      institution_domain: node['mconf-web']['shibboleth']['institution_domain'],
      service_name: node['mconf-web']['shibboleth']['service_name'],
      service_description: node['mconf-web']['shibboleth']['service_description'],
      admin_name: node['mconf-web']['shibboleth']['admin_name'],
      admin_email: node['mconf-web']['shibboleth']['admin_email']
   )
  end
end

# Apache website configuration
# Note: can't use web_app because it doesn't take variables
template "#{node['apache']['dir']}/sites-available/mconf-web.conf" do
  source "apache-site.conf.erb"
  mode 00644
  owner 'root'
  group 'root'
  variables certs
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


# Monit

package "monit"
service "monit"

template "/etc/monit/conf.d/mconf-web" do
  source "monit-config.erb"
  mode 00644
  owner "root"
  group "root"
  variables(
    deploy_to: node['mconf-web']['deploy_to_full'],
    rbenv_root: node['rbenv']['root_path']
  )
  notifies :restart, "service[monit]", :delayed
end
# TODO: restart the processes monitored by monit too, not only monit

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
