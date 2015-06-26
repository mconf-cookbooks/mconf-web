#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

override['build-essential']['compile_time'] = false

# rbenv + ruby + gems
# these attributes are used by the rbenv cookbook
override['rbenv']['rubies'] = [node['rbenv']['ruby']['version']]
override['rbenv']['global'] = node['rbenv']['ruby']['version']
override['rbenv']['gems'] = {
  node['rbenv']['ruby']['version'] => [
    { name: 'bundler',
      version: '1.7.2'
    },
    { name: 'passenger',
      version: node['passenger']['version']
    }
  ]
}

override['rbenv']['git_url'] = "https://github.com/sstephenson/rbenv.git"
override['rbenv']['git_ref'] = "v0.4.0"

# Passenger
override['passenger']['version']        = node['passenger']['version']
override['passenger']['max_pool_size']  = 6

# Need to use mpm_prefork since we are also using mod_php
# For more info search the web for "Apache is running a threaded MPM, but your PHP Module is not
# compiled to be threadsafe.  You need to recompile PHP."
if node['mconf-web']['with_mconf_home']
  override['apache']['mpm'] = 'prefork'
end

# Cache the full application path depending on whether capistrano is being used
if node['mconf-web']['deploy_with_cap']
  override['mconf-web']['deploy_to_full'] = "#{node['mconf-web']['deploy_to']}/current"
else
  override['mconf-web']['deploy_to_full'] = node['mconf-web']['deploy_to']
end

# Shibboleth
override['mconf-web']['shibboleth']['certificates']['certificate_content'] = ''
override['mconf-web']['shibboleth']['certificates']['shib_user'] = '_shibd'

override['mconf-web']['passenger']['conf_name'] = 'mconf-passenger'
