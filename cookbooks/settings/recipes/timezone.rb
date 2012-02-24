#puts node[:settings][:timezone]
#puts node[:settings][:utc]
#puts node[:settings][:arc]

template "/etc/sysconfig/clock" do
  source "clock.erb"
  group "root"
  owner "root"
  mode 0755
  variables(
     :timezone => node[:settings][:timezone],
     :utc => node[:settings][:utc],
     :arc => node[:settings][:arc]
  )
end

dir1,dir2 = node[:settings][:timezone].split('/')

if dir2.nil?
  link "/etc/localtime" do
    to "/usr/share/zoneinfo/#{dir1}" 
  end
else
  link "/etc/localtime" do
    to "/usr/share/zoneinfo/#{dir1}/#{dir2}" 
  end
end
