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
version          '1.0.0'

supports 'ubuntu', '>= 14.04'

suggests 'mconf-db'

depends 'ruby_build', '~> 1.0.0' # chef 12
depends 'ruby_rbenv', '~> 1.1.0' # chef 12
depends 'apache2', '~> 3.2.0'
depends 'passenger_apache2', '~> 3.0.0'
depends 'logrotate', '~> 1.9.0'
depends 'build-essential', '>= 2.0'
depends 'monit-ng', '~> 2.3.0' # chef 12

recipe 'mconf-web::default', 'Sets up an instance of Mconf-Web'
