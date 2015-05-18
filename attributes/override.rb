#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

override["build_essential"]["compiletime"] = false

ruby_version = '2.2.0'
override['rbenv']['rubies'] = [ruby_version]
override['rbenv']['global'] = ruby_version
override['rbenv']['gems'] = {
  ruby_version => [
    { name: 'bundler',
      version: '1.7.2'
    }
  ]
}

override['passenger']['version']     = '4.0.59'
override['passenger']['apache_mpm']  = nil
override['passenger']['root_path']   = "#{languages['ruby']['gems_dir']}/gems/passenger-#{passenger['version']}"
override['passenger']['module_path'] = "#{passenger['root_path']}/buildout/apache2/mod_passenger.so"
override['passenger']['max_pool_size'] = 6
override['passenger']['manage_module_conf'] = true
override['passenger']['package']['name'] = nil
# set package version to nil, the distro package may not be the same version
override['passenger']['package']['version'] = nil
override['passenger']['ruby_bin'] = languages['ruby']['ruby_bin']
override['passenger']['install_module'] = true

# Need to use mpm_prefork since we are also using mod_php
# For more info search the web for "Apache is running a threaded MPM, but your PHP Module is not
# compiled to be threadsafe.  You need to recompile PHP."
if node['mconf-web']['with_mconf_home']
  override['apache']['mpm'] = 'prefork'
end
