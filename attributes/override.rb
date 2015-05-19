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


# General definitions for ruby in an rbenv environment.
# These attributes are used internally by this cookbook only.
# e.g. /home/mconf/.rbenv/versions/2.2.0/lib/ruby/gems/2.2.0/gems/passenger-4.0.59/
override['rbenv']['root_path'] = "/home/#{node['mconf']['user']}/.rbenv"
override['rbenv']['ruby']['root_path'] = "#{rbenv['root_path']}/versions/#{rbenv['ruby']['version']}"
override['rbenv']['ruby']['gems_path'] = "#{rbenv['ruby']['root_path']}/lib/ruby/gems/#{rbenv['ruby']['version']}/gems"
override['rbenv']['ruby']['bin'] = "#{rbenv['ruby']['root_path']}/bin/ruby"

# Passenger
override['passenger']['version']        = node['passenger']['version']
override['passenger']['root_path']      = "#{rbenv['ruby']['gems_path']}/passenger-#{passenger['version']}"
override['passenger']['module_path']    = "#{passenger['root_path']}/buildout/apache2/mod_passenger.so"
override['passenger']['max_pool_size']  = 6
override['passenger']['ruby_bin']       = node['rbenv']['ruby']['bin']

# Need to use mpm_prefork since we are also using mod_php
# For more info search the web for "Apache is running a threaded MPM, but your PHP Module is not
# compiled to be threadsafe.  You need to recompile PHP."
if node['mconf-web']['with_mconf_home']
  override['apache']['mpm'] = 'prefork'
end

# Cache the full application path depending on whether capistrano is being used
if node['mconf-web']['deploy_with_cap']
  override['mconf-web']['deploy_to_full'] = node['mconf-web']['deploy_to']
else
  override['mconf-web']['deploy_to_full'] = "#{node['mconf-web']['deploy_to']}/current"
end
