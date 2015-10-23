mconf-web Cookbook
=================

This Chef cookbook installs an instance of [Mconf-Web](https://github.com/mconf/mconf-web), Mconf's web portal.

It installs and configures all the system dependencies needed to run Mconf-Web, except:

* The database. For that we use the cookbook [mconf-db](https://github.com/mconf-cookbooks/mconf-db).
* The source code and application configurations (the actual "deploy" of the application). For that we use Capistrano (see https://github.com/mconf/mconf-web-caphub) or do it manually (see [our wiki](https://github.com/mconf/mconf-web/wiki)).


Requirements
------------

This cookbook is tested with Chef 11 (latest version). It may work with or without modification on newer versions of Chef, but Chef 11 is recommended.

Platform
--------

This cookbook currently supports Ubuntu 14.04. It will always be updated to support the OS version supported by Mconf-Web, which is usually the latest LTS version of Ubuntu.


Attributes
----------

#### mconf-web::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Required</th>
  </tr>
  <tr>
    <td><tt>['mconf-web']['domain']</tt></td>
    <td>String</td>
    <td>Domain or IP</td>
    <td>true</td>
  </tr>
</table>

For a complete list of attributes see [attributes/default.rb](https://github.com/mconf-cookbooks/mconf-web/blob/master/attributes/default.rb).


Recipes
-------

#### default

Installs everything needed for Mconf-Web, including:

* Installs packages;
* Creates deploy directories;
* Installs ruby;
* Installs and configures apache and passenger;
* Configures SSL certificates, if configured to;
* Installs and configures monit;
* Configues logrotate.


Usage
-----

#### mconf-web::default

Include `mconf-web` in your node's `run_list` along with the required attributes:

```json
{
  "name":"my_node",
  "mconf-web": {
    "user": "mconf",
    "app_group": "www-data",
    "domain": "192.168.0.100",
    "resque": {
      "workers": 2
    }
  },
  "run_list": [
    "recipe[mconf-web]"
  ]
}
```
