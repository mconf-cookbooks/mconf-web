#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

override['build-essential']['compile_time'] = false

# Passenger
override['passenger']['version']        = node['mconf-web']['passenger_version']
override['passenger']['max_pool_size']  = 6
override['mconf-web']['passenger']['conf_name'] = 'mconf-passenger'

# rbenv + ruby + gems
# these attributes are used by the rbenv cookbook
override['rbenv']['upgrade'] = true
override['rbenv']['ruby']['version'] = node['mconf-web']['ruby_version']
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
override['rbenv']['git_ref'] = node['mconf-web']['rbenv_version']

override['ruby_build']['upgrade'] = true
override['ruby_build']['git_ref'] = "master"

# Need to use mpm_prefork since we are also using mod_php
# For more info search the web for "Apache is running a threaded MPM, but your PHP Module is not
# compiled to be threadsafe.  You need to recompile PHP."
if node['mconf-web']['with_mconf_home']
  override['apache']['mpm'] = 'prefork'
end

packages = %w{
  git libruby aspell-en libxml2-dev libxslt1-dev nfs-common libcurl4-openssl-dev
  libmagickcore-dev libmagickwand-dev imagemagick zlib1g-dev libreadline-dev libffi-dev
}
if node['platform'] == 'ubuntu' && Gem::Version.new(node['platform_version']) >= Gem::Version.new('16.04')
  packages << 'openjdk-8-jre'
  override['mconf-web']['packages']['apache2'] = %W( apache2 apache2-dev libapr1-dev libaprutil1-dev libcurl4-gnutls-dev )
else
  packages << 'openjdk-7-jre'
  override['mconf-web']['packages']['apache2'] = %W( apache2 apache2-prefork-dev apache2-mpm-worker libapr1-dev libcurl4-gnutls-dev libapache2-mod-xsendfile )
end
override['mconf-web']['packages']['general'] = packages

# Cache the full application path depending on whether capistrano is being used
if node['mconf-web']['deploy_with_cap']
  override['mconf-web']['deploy_to_full'] = "#{node['mconf-web']['deploy_to']}/current"
else
  override['mconf-web']['deploy_to_full'] = node['mconf-web']['deploy_to']
end

# Shibboleth
override['mconf-web']['shibboleth']['certificates']['certificate_content'] = ''
override['mconf-web']['shibboleth']['certificates']['shib_user'] = '_shibd'

# Default options for monit.
# Most of the paths and options here are copied from the defaults in the Ubuntu packages.
override["monit"]["init_style"]             = "upstart"
override["monit"]["config"]["poll_freq"]    = node['mconf-web']['monit']['interval']
override["monit"]["config"]['start_delay']  = node['mconf-web']['monit']['start_delay']
override["monit"]["config"]['mail_subject'] = "#{node['mconf-web']['domain']}: $ACTION $SERVICE ($DESCRIPTION)"
# override["monit"]["config"]['mail_subject'] = "$SERVICE ($ACTION) $EVENT at $DATE"
override["monit"]["config"]['mail_message'] = <<-EOT
Domain: #{node['mconf-web']['domain']}
Event: $EVENT
Host: $HOST
Service: $SERVICE
Date: $DATE
Action: $ACTION
Description: $DESCRIPTION

Your faithful employee,
Monit
EOT

if node['mconf-web']['monit']['enable_alerts']
  override["monit"]["config"]['mail_from'] = node['mconf-web']['monit']['alert_from']

  override["monit"]["config"]["mail_servers"] = [
    {
      "hostname" => node['mconf-web']['monit']['smtp']['server'],
      "port" => node['mconf-web']['monit']['smtp']['port'],
      "username" => node['mconf-web']['monit']['smtp']['username'],
      "password" => node['mconf-web']['monit']['smtp']['password'],
      "security" => node['mconf-web']['monit']['smtp']['security'],
      "timeout" => node['mconf-web']['monit']['smtp']['timeout']
    }
  ]

  if node['mconf-web']['monit']['alert_to'].kind_of?(Array)
    alerts = node['mconf-web']['monit']['alert_to']
  elsif node['mconf-web']['monit']['alert_to'].kind_of?(String)
    alerts = [
      {
        "name" => node['mconf-web']['monit']['alert_to']
      }
    ]
  else
    alerts = [
      node['mconf-web']['monit']['alert_to']
    ]
  end
  override["monit"]["config"]["alert"] = alerts
end
