#
# Cookbook Name:: tomcat
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "java"
include_recipe "tomcat"

template "/etc/tomcat6/web.xml" do
  source "web.xml.sslonly.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "tomcat")
end

template "/var/lib/tomcat6/webapps/ROOT/server_error.html" do
  source "server_error.erb"
  owner "tomcat6"
  group "tomcat6"
  mode "0644"
  notifies :restart, resources(:service => "tomcat")
end

template "/var/lib/tomcat6/webapps/ROOT/file_not_found.html" do
  source "file_not_found.erb"
  owner "tomcat6"
  group "tomcat6"
  mode "0644"
  notifies :restart, resources(:service => "tomcat")
end
