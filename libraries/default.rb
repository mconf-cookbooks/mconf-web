#
# Cookbook Name:: mconf-web
# Recipe:: default
# Author:: Leonardo Crauss Daronco (<daronco@mconf.org>)
#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

def versioned_template(name, version)
  if !version.nil? && has_template?("#{version}/#{name}")
    "#{version}/#{name}"
  else
    name
  end
end

def has_source?(source, segment, cookbook=nil)
  cookbook ||= cookbook_name
  begin
    run_context.cookbook_collection[cookbook].
      send(:find_preferred_manifest_record, run_context.node, segment, source)
  rescue Chef::Exceptions::FileNotFound
    nil
  end
end

def has_template?(tmpl, cookbook=nil)
  has_source?(tmpl, :templates, cookbook)
end
