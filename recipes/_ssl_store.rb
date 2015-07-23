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

unless node['mconf-web']['ssl']['store']['custom_certificates'].empty?
  ruby_block "ssl store: copy certificate to store" do
    block do
      cmd = Mixlib::ShellOut.new("ruby -e \"require 'openssl'; puts OpenSSL::X509::DEFAULT_CERT_DIR\"")
      cmd.run_command
      node.run_state['ssl_store_path'] = cmd.stdout.strip
      node['mconf-web']['ssl']['store']['custom_certificates'].each do |cert|
        res = Chef::Resource::CookbookFile.new("#{node.run_state['ssl_store_path']}/#{cert}", run_context)
        res.cookbook 'mconf-web'
        res.source cert
        res.owner 'root'
        res.group 'root'
        res.mode '0644'
        res.run_action(:create)
      end
    end
    action :run
    notifies :run, 'execute[ssl store: c_rehash]', :immediately
  end

  execute 'ssl store: c_rehash' do
    cwd node.run_state['ssl_store_path']
    command 'c_rehash'
    action :nothing
  end
end
