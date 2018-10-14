include_recipe "nginx"

nginx_site "opsworks-demo" do
  template "opsworks-demo.erb"
  action :enable
end

remote_directory "/var/www/opsworks-demo" do
  source "teaser_page"
  owner "root"
  group "root"
  mode "0755"
  files_mode "0755"
  overwrite true
  action :create
end

template "/var/www/opsworks-demo/index.html" do
  source "opsworks-index.html.erb"
  owner "root"
  group "root"
  mode "0755"
  action :create
end