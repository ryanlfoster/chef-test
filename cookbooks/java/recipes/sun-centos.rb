#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: java
# Recipe:: sun
#
# Copyright 2010-2011, Opscode, Inc.
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

#   "jdk-#{node['java']['version']}-ea-linux-#{node['java']['arch']}.rpm"

#Added custom repo for java

cookbook_file "/etc/yum.repos.d/custom.repo" do
  source "custom.repo"
  mode "0644"
  action :create_if_missing
end

#pkgs_list = ["jdk-#{node['java']['version']}-ea-linux-#{node['java']['arch']}"]

%w{ sysstat  
jdk
sun-javadb-client
sun-javadb-common
sun-javadb-core
sun-javadb-demo
sun-javadb-docs
sun-javadb-javadoc
}.each do |pkg|
  package pkg do
    action :install
    options "-y"
  end
end


#ln -s /usr/java/jdk1.6.0_25 /opt/jdk6
link "/opt/jdk6" do
  to "/usr/java/jdk1.6.0_25"
end
