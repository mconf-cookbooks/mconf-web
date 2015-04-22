#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

# Database configurations
default['db']['name'] = 'mconf_production'
default['db']['user'] = 'mconf'
default['db']['passwords']['root'] = 'password'
default['db']['passwords']['app'] = 'password'

default['mconf']['user'] = 'mconf'
default['mconf']['apache-group'] = 'www-data'

default['mconf-web']['domain'] = '192.168.0.100'
default['mconf-web']['deploy_to'] = '/var/www/mconf-web/current'
