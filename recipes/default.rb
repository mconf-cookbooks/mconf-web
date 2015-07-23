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
   zlib1g-dev libreadline-dev libffi-dev nfs-common libcurl4-openssl-dev openjdk-7-jre
   libapache2-mod-xsendfile}.each do |pkg|
  package pkg
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
    file = node['mconf-web']['ssl']['certificates'][cert_name]
    if file && file.strip != ''
      path = "/etc/apache2/ssl/#{file}"

      cookbook_file path do
        source file
        owner 'root'
        group node['mconf-web']['app_group']
        mode 00640
        action :create
      end

      certs[cert_name] = path
    end
  end
end
certs['ca_certificate_path'] = node['mconf-web']['ssl']['certificates']['ca_certificate_path']

# make sure the directory exists
if certs['ca_certificate_path'] && certs['ca_certificate_path'].strip != ''
  directory certs['ca_certificate_path'] do
    owner 'root'
    group node['mconf-web']['app_group']
    mode 00640
    recursive true
    action :create
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

  # Copy local certificates if we're not generating certificates
  ['certificate_file', 'certificate_key_file'].each do |name|
    file = node['mconf-web']['shibboleth']['certificates'][name]
    if file && file.strip != ''
      path = "#{node['mconf-web']['shibboleth']['certificates']['folder']}/#{file}"
      user = node['mconf-web']['shibboleth']['certificates']['shib_user']
      filemode = name == 'certificate_key_file' ? 00600 : 00640

      cookbook_file path do
        source file
        owner user
        group user
        mode filemode
        action :create
        only_if { !node['mconf-web']['shibboleth']['certificates']['create'] }
      end
    end
  end

  ruby_block "collect shib certificate content" do
    block do
      file = "#{node['mconf-web']['shibboleth']['certificates']['folder']}/#{node['mconf-web']['shibboleth']['certificates']['certificate_file']}"
      output = IO.read(file)
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


include_recipe "mconf-web::_ssl_store"


# Monit

package "monit"
service "monit"

monit_template = versioned_template("monit-config.erb", node['mconf-web']['version'])
template "/etc/monit/conf.d/mconf-web" do
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
  path [ "#{node['mconf-web']['deploy_to_full']}/log/*.log" ]
  options [ 'missingok', 'compress', 'copytruncate', 'notifempty' ]
  frequency 'daily'
  rotate 20
  size '100M'
  create "644 #{node['mconf-web']['user']} #{node['mconf-web']['app_group']}"
end
