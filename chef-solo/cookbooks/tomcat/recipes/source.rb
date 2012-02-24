#
# Cookbook Name:: tomcat
# Recipe:: source
#
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

directory "/usr/src" do
  mode 0755
end

remote_file "/usr/src/#{node[:tomcat][:tarball_name]}.tar.gz" do
  source "#{node[:tomcat][:download_url]}/#{node[:tomcat][:tarball_name]}.tar.gz"
  action :create_if_missing
end

bash "untar tomcat" do
  cwd "/usr/src"
  code <<-EOH
    tar zxf /usr/src/#{node[:tomcat][:tarball_name]}.tar.gz -C /opt
  EOH
end

link "/opt/tomcat" do
  to "/opt/#{node[:tomcat][:tarball_name]}"
end

template "/opt/tomcat/conf/tomcat-users.xml" do
  source "tomcat-users.xml.erb"
  owner "root"
  group "root"
  mode "0644"
#  notifies :restart, resources(:service => "tomcat")
end


cookbook_file "/opt/tomcat/bin/setenv.sh" do
  source "setenv.sh"
  owner "root"
  group "root"
  mode "0755"
end

case node['platform']
when "centos", "redhat", "fedora"
  cookbook_file "/etc/init.d/tomcat" do
    source "init.d.tomcat7.rhel6"
    owner "root"
    group "root"
    mode "0755"
  end
end

execute "chown -R tomcat:tomcat /opt/tomcat* /opt/#{node[:tomcat][:tarball_name]}" do
end

service "tomcat" do
  supports :restart => true, :reload => true
  action [ :enable, :start ]
end

