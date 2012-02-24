cq_home = "/opt/cq/#{node[:cq][:cq_instance_type]}" 
sling_properties = "#{cq_home}/crx-quickstart/launchpad/sling.properties"

directory "/opt/cq-#{node[:cq][:version]}" do
  owner 'root'
  group 'root'
  mode 0755
  not_if "ls -al /opt/cq-#{node[:cq][:version]}"
end

link "/opt/cq" do
  to "/opt/cq-#{node[:cq][:version]}"
  not_if "ls -al /opt/cq"
end

directory cq_home do
  owner 'root'
  group 'root'
  mode 0755
  not_if "ls -al #{cq_home}" 
end

remote_file "#{cq_home}/cq5-#{node[:cq][:cq_instance_type]}-#{node[:cq][:cq_instance_port]}.jar" do
  source "#{node[:cq][:url_download]}/cq-quickstart-#{node[:cq][:version]}.jar"
  mode "0755"
  not_if "ls -al #{cq_home}/cq5-#{node[:cq][:cq_instance_type]}-#{node[:cq][:cq_instance_port]}.jar"
end

remote_file "#{cq_home}/license.properties" do
  source "#{node[:cq][:url_download]}/license.properties"
  mode "0755"
end

execute "cd #{cq_home}; java -jar cq5-#{node[:cq][:cq_instance_type]}-#{node[:cq][:cq_instance_port]}.jar -unpack" do 
not_if "ls -al #{cq_home}/crx-quickstart" 
end

cookbook_file '/etc/init.d/cq' do
  source 'init_cq'
  owner 'root'
  group 'root'
  mode 0755
end

#Add entries for sling properties
#
execute "echo \"sling.jcrinstall.folder.name.regexp=.*/(install|config)(.#{node[:cq][:cq_instance_type]}|.#{node[:cq][:environment]})?$\" >> #{sling_properties}" do
not_if "grep sling.jcrinstall #{sling_properties}" 
end

execute "echo \"sling.run.modes=#{node[:cq][:cq_instance_type]},#{node[:cq][:environment]}\" >> #{sling_properties}" do
not_if "grep sling.run.modes #{sling_properties}" 
end

#Make sure permissions are set to cq user and group

execute "chown -R cq:cq /opt/cq /opt/cq-#{node[:cq][:version]}" do 
end

file2append = '/etc/security/limits.conf'

Chef::Log.info "Appending #{file2append}..."

if File.exists?(file2append)
    file file2append do
      additional_content = %Q{
# Automatically added to #{file2append}
*       hard    nofile  32768
*       soft    nofile  8192
# End appending of #{file2append}
}

      only_if do
        current_content = File.read(file2append)
        current_content.index(additional_content).nil?
      end

      current_content = File.read(file2append)
      orig_content    = current_content.gsub(/\n# Automatically added to #{file2append}(.|\n)*# End appending of #{file2append}\n/, '')

      owner "root"
      group "root"
      mode "0644"
      content orig_content + additional_content
    end
end

service "cq" do
  supports :restart => true, :reload => true
  action [ :enable, :start ]
end


