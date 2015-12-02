#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

default['mconf-web']['user']            = node['mconf']['user'] || 'mconf'
default['mconf-web']['app_group']       = node['mconf']['app_group'] || 'www-data'
default['mconf-web']['version']         = nil
default['mconf-web']['domain']          = '192.168.0.100'
default['mconf-web']['deploy_to']       = '/var/www/mconf-web'
default['mconf-web']['deploy_with_cap'] = true
default['mconf-web']['remove_www']      = true
default['mconf-web']['http_protocol']   = 'http'

# Maximum size for uploads in bytes
# Set to `nil` to disable limiting
default['mconf-web']['max_upload_size'] = '15728640' # 15 MB in bytes (Apache uses 1024 as multiplier)

# Ruby and gems
default['rbenv']['ruby']['version'] = '2.2.0'
default['passenger']['version']     = '4.0.59'

# Whether the application is being installed in the same server that will
# also have Mconf-Home. If so, SSL has to be turned on, otherwise it won't
# behave properly! (Mconf-Web runs on 443, Mconf-Home on 80.)
default['mconf-web']['with_mconf_home'] = false

# Resque
default['mconf-web']['resque']['workers'] = 3

# SSL/HTTPS
default['mconf-web']['ssl']['enable'] = false
default['mconf-web']['ssl']['hsts'] = false # turn on/off HSTS
default['mconf-web']['ssl']['certificates']['certificate_file'] = ''
default['mconf-web']['ssl']['certificates']['certificate_key_file'] = ''
default['mconf-web']['ssl']['certificates']['certificate_chain_file'] = ''
default['mconf-web']['ssl']['certificates']['ca_certificate_file'] = ''
default['mconf-web']['ssl']['certificates']['ca_certificate_path'] = nil

# Custom certificates to be added to the SSL store
# More information at: http://mislav.uniqpath.com/2013/07/ruby-openssl/
default['mconf-web']['ssl']['store']['custom_certificates'] = []

# Shibboleth
default['mconf-web']['shibboleth']['enable'] = false
default['mconf-web']['shibboleth']['federation'] = 'chimarrao', # 'chimarrao' or 'cafe'
default['mconf-web']['shibboleth']['certificates']['certificate_file'] = 'sp-cert.pem'
default['mconf-web']['shibboleth']['certificates']['certificate_key_file'] = 'sp-key.pem'
default['mconf-web']['shibboleth']['certificates']['folder'] = '/etc/shibboleth'

# If true, will create self-signed certificates (only if they don't exist yet).
# The path to the certificates in
#   * node['mconf-web']['shibboleth']['certificates']['certificate_file']
#   * node['mconf-web']['shibboleth']['certificates']['certificate_key_file']
# will be overridden with the paths to the certificates generated.
default['mconf-web']['shibboleth']['certificates']['create'] = false

# For the metadata file
default['mconf-web']['shibboleth']['institution'] = 'My Institution'
default['mconf-web']['shibboleth']['institution_domain'] = node['mconf-web']['domain']
default['mconf-web']['shibboleth']['service_name'] = 'My Service'
default['mconf-web']['shibboleth']['service_description'] = 'My service is described as...'
default['mconf-web']['shibboleth']['admin_name'] = 'Admin Name'
default['mconf-web']['shibboleth']['admin_email'] = 'admin@institution'

# Login via certificate
default['mconf-web']['cert_login']['enable']       = false
default['mconf-web']['cert_login']['verify_depth'] = 2

# Monit
# Used for monit's "set daemon"
default['mconf-web']['monit']['interval']          = 30 # in seconds
# Disable alerts by default
default['mconf-web']['monit']['enable_alerts']     = false
# You can set it to a single string with an email, that will receive all events,
# or set to an object (or an array of objects) with the format:
#
# [
#   {
#     "name": "root@localhost",
#     "but_not_on": [ "nonexist" ]
#   },
#   {
#     "name": "netadmin@localhost",
#     "only_on": [ "nonexist", "timeout", "icmp", "connection"]
#   },
#   {
#     "name": "iwantall@localhost"
#   }
# ]
#
# See Monit's documentation for "set alert" at
# https://mmonit.com/monit/documentation/monit.html).
default['mconf-web']['monit']['alert_to']          = 'issues@foo'
default['mconf-web']['monit']['alert_from']        = 'support@foo'
# SMTP configurations
default['mconf-web']['monit']['smtp']['server']    = 'smtp.foo'
default['mconf-web']['monit']['smtp']['port']      = 587
default['mconf-web']['monit']['smtp']['username']  = 'username'
default['mconf-web']['monit']['smtp']['password']  = 'password'
default['mconf-web']['monit']['smtp']['timeout']   = '30 seconds'
default['mconf-web']['monit']['smtp']['security']  = 'TLSV1'
