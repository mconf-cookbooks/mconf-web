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

node.run_state['mconf-web-certs'] = certs
