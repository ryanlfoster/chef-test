group "cq" do
  gid node[:cq][:gid]
  not_if 'grep cq /etc/group'
end

user "cq" do
  comment "CQ user"
  uid node[:cq][:uid]
  gid node[:cq][:gid]
  home "/home/cq"
  not_if 'grep cq /etc/passwd'
end
