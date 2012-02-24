group "tomcat" do
  gid node[:tomcat][:gid]
  not_if 'grep tomcat /etc/group'
end

user "tomcat" do
  comment "Tomcat user"
  uid node[:tomcat][:uid]
  gid node[:tomcat][:gid]
  home "/home/tomcat"
  shell "/sbin/nologin"
  not_if 'grep tomcat /etc/passwd'
end

