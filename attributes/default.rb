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
default['mconf-web']['http_protocol']   = 'http'

# Maximum size for uploads in bytes
# Set to `nil` to disable limiting
default['mconf-web']['max_upload_size'] = '15728640' # 15 MB in bytes (Apache uses 1024 as multiplier)

# Ruby and gems
default['mconf-web']['ruby_version']      = '2.2.5'
default['mconf-web']['rbenv_version']     = 'master'
if node['platform'] == 'ubuntu' && Gem::Version.new(node['platform_version']) >= Gem::Version.new('16.04')
  default['mconf-web']['passenger_version'] = '5.3.2'
else
  default['mconf-web']['passenger_version'] = '4.0.59'
end
default['mconf-web']['rack_version'] = '2.0.5'

# Whether the application is being installed in the same server that will
# also have Mconf-Home. If so, SSL has to be turned on, otherwise it won't
# behave properly! (Mconf-Web runs on 443, Mconf-Home on 80.)
default['mconf-web']['with_mconf_home'] = false

# Resque
default['mconf-web']['resque']['workers'] = 6
default['mconf-web']['resque']['scheduler'] = true

# SSL/HTTPS
default['mconf-web']['ssl']['enable'] = false
# turn on/off HSTS
default['mconf-web']['ssl']['hsts'] = false
default['mconf-web']['ssl']['certificates_path'] = '/etc/apache2/ssl'
default['mconf-web']['ssl']['certificates']['certificate_file'] = ''
default['mconf-web']['ssl']['certificates']['certificate_key_file'] = ''
default['mconf-web']['ssl']['certificates']['certificate_chain_file'] = ''
default['mconf-web']['ssl']['certificates']['ca_certificate_file'] = ''
default['mconf-web']['ssl']['certificates']['ca_certificate_path'] = nil

# To concat certificates into a single file. Example:
#   "concat_certificates": {
#     "output": "CA-concat.pem",
#     "inputs": [
#       "another-cert.pem",
#       "all-CAs.pem"
#     ]
#   }
default['mconf-web']['ssl']['concat_certificates'] = nil

# Custom certificates to be added to the SSL store
# More information at: http://mislav.uniqpath.com/2013/07/ruby-openssl/
default['mconf-web']['ssl']['store']['custom_certificates'] = []

# Shibboleth
default['mconf-web']['shibboleth']['enable'] = false
default['mconf-web']['shibboleth']['federation'] = 'chimarrao', # 'chimarrao' or 'cafe'
default['mconf-web']['shibboleth']['support_email'] = 'support@localhost'
default['mconf-web']['shibboleth']['certificates']['certificate_file'] = 'sp-cert.pem'
default['mconf-web']['shibboleth']['certificates']['certificate_key_file'] = 'sp-key.pem'
default['mconf-web']['shibboleth']['certificates']['folder'] = '/etc/shibboleth'
# Certificate files can be generated with:
# shib-keygen -y 3 -h my-domain.mconf.com -e https://my-domain.mconf.com/shibboleth -u _shibd -g _shibd -o .

# Set a list of servers to use memcached as the store for shibd
# If nil, will use the default memory storage
# Example:
#   [ '200.130.10.10:11211', '200.130.10.11:11211' ]
default['mconf-web']['shibboleth']['memcached_servers'] = nil

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

# Custom redirects for Apache (array of strings with domains)
# Will redirect any of these domains to the main domain configured with Mconf-Web
# Can be used to remove "www", add to the array e.g. "www.mconf.org"
default['mconf-web']['apache']['domain_redirects'] = []

# Custom internal redirects. Example:
#   default['mconf-web']['apache']['redirects'] = [
#     { 'from': '^/site$', 'to': '/site/pt' }
#   ]
default['mconf-web']['apache']['redirects'] = []

# Routes to cache. Example:
#   default['mconf-web']['apache']['cache']['locations'] = [
#     "^/conference/rooms/(.*)/running.json"
#   ]
default['mconf-web']['apache']['cache']['enable'] = false
default['mconf-web']['apache']['cache']['maxsize'] = 102400 # CacheSocacheMaxSize
default['mconf-web']['apache']['cache']['locations'] = []

# Health check paths, will make apache respond them with a 200 OK:
#   default['mconf-web']['apache']['health_checks'] = [
#     { 'method': 'HEAD', 'path': '^/$' }
#   ]
default['mconf-web']['apache']['health_checks'] = []

default['mconf-web']['apache']['metrics']['enable'] = false
default['mconf-web']['apache']['metrics']['user'] = 'default'
default['mconf-web']['apache']['metrics']['password'] = 'changeme'
# Example:
#   default['mconf-web']['apache']['metrics']['endpoints'] = [
#     { 'path': '/metrics', port: 9100 }
#   ]
default['mconf-web']['apache']['metrics']['endpoints'] = []
default['mconf-web']['apache']['metrics']['shib_conf_name'] = 'shib2-auth'

# Monit
# Used for monit's "set daemon"
default['mconf-web']['monit']['interval']          = 30 # interval between checks, in seconds
default['mconf-web']['monit']['start_delay']       = 0 # in seconds
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

# logrotate options
# by default keeps one log file per day, during 3 months
default['mconf-web']['logrotate']['frequency'] = 'daily'
default['mconf-web']['logrotate']['rotate']    = 90
default['mconf-web']['logrotate']['size']      = nil

# logrotate options for apache
# by default keeps one log file per day, during ~3 months
default['mconf-web']['apache']['logrotate']['frequency'] = 'daily'
default['mconf-web']['apache']['logrotate']['rotate']    = 90
default['mconf-web']['apache']['logrotate']['size']      = nil

default['passenger']['max_pool_size'] = 6
default['passenger']['min_instances'] = 2
default['passenger']['max_requests'] = 0
