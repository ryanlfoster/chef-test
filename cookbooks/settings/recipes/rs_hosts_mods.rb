internal_ip = `ifconfig eth1| grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | awk '{print $1}'`.gsub("\n","")
hostname = `hostname`.gsub("\n","")

template "/etc/hosts" do
  source "hosts.erb"
  group "root"
  owner "root"
  mode 0755
  variables(
     :internal_ip => internal_ip,
     :hostname => hostname
  )
end

