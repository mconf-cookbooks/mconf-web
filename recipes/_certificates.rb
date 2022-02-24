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
      path = "#{node['mconf-web']['ssl']['certificates_path']}/#{file}"

      cookbook_file path do
        source file
        owner 'root'
        group node['mconf-web']['app_group']
        mode 00640
        action :create
        only_if { run_context.has_cookbook_file_in_cookbook?('mconf-web', file) }
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

  # NOTE: the test
  #   !node['packages'].keys.include?('libapache2-mod-shib2')
  # means: if the package 'libapache2-mod-shib2' is not installed yet
  # to force the blocks below to run again, purge it 'aptitude purge libapache2-mod-shib2'

  # see https://depts.washington.edu/bitblog/2018/06/libcurl3-libcurl4-shibboleth-php-curl-ubuntu-18-04/
  if node['platform'] == 'ubuntu' &&
     Gem::Version.new(node['platform_version']) >= Gem::Version.new('18.04')

    package 'libcurl3' do
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) < Gem::Version.new('20.04')
      }
    end
    package ['libcurl3-gnutls', 'libcurl3-nss'] do
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) >= Gem::Version.new('20.04')
      }
    end

    remote_file 'Keep a backup of libcurl3' do
      path '/usr/lib/x86_64-linux-gnu/libcurl3.so.4.5.0'
      source 'file:///usr/lib/x86_64-linux-gnu/libcurl.so.4.5.0'
      owner 'root'
      group 'root'
      mode '0755'
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) < Gem::Version.new('20.04')
      }
    end
    remote_file 'Keep a backup of libcurl3' do
      path '/usr/lib/x86_64-linux-gnu/libcurl3.so.4.6.0'
      source 'file:///usr/lib/x86_64-linux-gnu/libcurl.so.4.6.0'
      owner 'root'
      group 'root'
      mode '0755'
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) >= Gem::Version.new('20.04')
      }
    end

    package ['libcurl4', 'liblog4shib1v5', 'libxerces-c3.2', 'libxml-security-c17v5'] do
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) < Gem::Version.new('20.04')
      }
    end
    package ['libcurl4', 'liblog4shib2', 'libxerces-c3.2', 'libxml-security-c20'] do
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) >= Gem::Version.new('20.04')
      }
    end

    file '/usr/lib/x86_64-linux-gnu/libcurl.so.4' do
      action :delete
      only_if { !node['packages'].keys.include?('libapache2-mod-shib2') }
    end

    link '/usr/lib/x86_64-linux-gnu/libcurl.so4' do
      to '/usr/lib/x86_64-linux-gnu/libcurl.so.4.5.0'
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) < Gem::Version.new('20.04')
      }
    end
    link '/usr/lib/x86_64-linux-gnu/libcurl.so4' do
      to '/usr/lib/x86_64-linux-gnu/libcurl.so.4.6.0'
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) >= Gem::Version.new('20.04')
      }
    end

    cookbook_file '/tmp/libxmltooling7-local.deb' do
      source 'libxmltooling7-local.deb'
      mode '0755'
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) < Gem::Version.new('20.04')
      }
    end
    dpkg_package '/tmp/libxmltooling7-local.deb' do
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) < Gem::Version.new('20.04')
      }
    end
    package ['libxmltooling8'] do
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) >= Gem::Version.new('20.04')
      }
    end

    directory '/etc/systemd/system/shibd.service.d/' do
      owner 'root'
      group 'root'
      mode '0755'
      recursive true
      action :create
      only_if { !node['packages'].keys.include?('libapache2-mod-shib2') }
    end

    file '/etc/systemd/system/shibd.service.d/override.conf' do
      content %(
[Service]
Environment="LD_PRELOAD=libcurl3.so.4.5.0"
      )
      mode '0755'
      owner 'root'
      group 'root'
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) < Gem::Version.new('20.04')
      }
    end
    file '/etc/systemd/system/shibd.service.d/override.conf' do
      content %(
[Service]
Environment="LD_PRELOAD=libcurl3.so.4.6.0"
      )
      mode '0755'
      owner 'root'
      group 'root'
      only_if {
        !node['packages'].keys.include?('libapache2-mod-shib2') &&
          Gem::Version.new(node['platform_version']) >= Gem::Version.new('20.04')
      }
    end
  end

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
        certificate_key_file: File.basename(node['mconf-web']['shibboleth']['certificates']['certificate_key_file']),
        support_email: node['mconf-web']['shibboleth']['support_email']
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

if node['mconf-web']['ssl']['concat_certificates']
  path = node['mconf-web']['ssl']['certificates_path']
  output = node['mconf-web']['ssl']['concat_certificates']['output']
  inputs = node['mconf-web']['ssl']['concat_certificates']['inputs']

  # in case a file being concat'ed is not there yet, copy from the cookbook
  inputs.each do |file|
    cookbook_file File.join(path, file) do
      source file
      owner 'root'
      group node['mconf-web']['app_group']
      mode 00640
      action :create
      only_if { run_context.has_cookbook_file_in_cookbook?('mconf-web', file) }
    end
  end

  ruby_block "concat certificates" do
    block do
      File.open(File.join(path, output), 'w') do |file|
        inputs.each do |input|
          file.write(File.read(File.join(path, input)))
        end
      end
    end
  end
end
