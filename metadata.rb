#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

name             'mconf-web'
maintainer       'mconf'
maintainer_email 'mconf@mconf.org'
license          'MPL v2.0'
description      'Sets up an instance of Mconf-Web'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports 'ubuntu', '>= 14.04'

suggests 'mconf-db'
depends  'ruby_build', '0.8.0'
depends  'apache2', '3.0.1'
depends  'logrotate', '1.1.0'
depends  'build-essential', '2.0.6'

# must be the version from https://github.com/chef-rbenv/ruby_rbenv
# not the rbenv in chef's supermarket
# TODO: migrate to ruby_rbenv >= 1.0, that is now in the supermarket
# NOTE: version 0.9.0 already requires chef 12
depends  'rbenv', '0.8.1'
# depends  'ruby_rbenv', '1.0.0'

recipe 'mconf-web::default', 'Sets up an instance of Mconf-Web'
