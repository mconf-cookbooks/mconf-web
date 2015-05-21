#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

default['mconf']['user'] = 'mconf'
default['mconf']['app_group'] = 'www-data'

default['rbenv']['ruby']['version'] = '2.2.0'
default['passenger']['version'] = '4.0.59'

default['mconf-web']['domain'] = '192.168.0.100'
default['mconf-web']['deploy_to'] = '/var/www/mconf-web'
default['mconf-web']['deploy_with_cap'] = true
default['mconf-web']['with_mconf_home'] = false
default['mconf-web']['ssl'] = {
  'enable' => false,
  'certificates' => {
    'file' => 'mconf-web.crt',
    'key' => 'mconf-web.key'
  }
}

default['mconf-web']['shibboleth']['enable'] = false
default['mconf-web']['shibboleth']['federation'] = 'chimarrao', # only 'chimarrao' available for now
default['mconf-web']['shibboleth']['certificates']['certificate_file'] = '/etc/shibboleth/sp-cert.pem'
default['mconf-web']['shibboleth']['certificates']['certificate_key_file'] = '/etc/shibboleth/sp-key.pem'

# If true, will create self-signed certificates (only if they don't exist yet).
# The path to the certificates in 'certificate_file' and 'certificate_key_file' will
# be overridden with the paths to the certificates generated.
default['mconf-web']['shibboleth']['certificates']['create'] = false

# For the metadata
default['mconf-web']['shibboleth']['institution'] = 'My Institution'
default['mconf-web']['shibboleth']['institution_domain'] = node['mconf-web']['domain']
default['mconf-web']['shibboleth']['service_name'] = 'My Service'
default['mconf-web']['shibboleth']['service_description'] = 'My service is described as...'
default['mconf-web']['shibboleth']['admin_name'] = 'Admin Name'
default['mconf-web']['shibboleth']['admin_email'] = 'admin@institution'
