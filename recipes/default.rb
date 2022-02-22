#
# Cookbook:: remote_rasterize
# Recipe:: default
#
# Copyright:: 2021, The Authors, All Rights Reserved.



apt_update

package ['python3-pip', 'zip', 'unzip'] do
  action :install
end

execute 'install_ipython' do
  command 'pip install ipython'
  action :run
  not_if do ::File.exists?('/usr/local/bin/ipython') end
end

user 'pcapfab' do
  action :create
  system true
end

directory '/opt/pcapfab' do
  owner 'pcapfab'
  group 'pcapfab'
  mode '0755'
  action :create
end

template '/opt/pcapfab/pcapfab.py' do
  source 'pcapfab.py.erb'
  owner 'pcapfab'
  group 'pcapfab'
  mode '0644'
end


pip_packages = ['fastapi', 'pydantic', 'uvicorn', 'gunicorn']


pip_packages.each do |pip_pkg|

  execute "pip_#{pip_pkg}" do
    command "pip3 install #{pip_pkg} && touch /opt/pcapfab/pip_dep_#{pip_pkg}_installed"
    action :run
    not_if do ::File.exists?("/opt/pcapfab/pip_dep_#{pip_pkg}_installed") end
  end

end


execute 'generate_certs' do
  command 'openssl req -newkey rsa:4096 -new -nodes -x509 -days 1826 -keyout /opt/pcapfab/key.pem -out /opt/pcapfab/cert.pem -subj "/C=US/ST=Washington/L=Seattle/O=KP/CN=pcapfab.com"'
  user 'pcapfab'
  action :run
  not_if do ::File.exists?('/opt/pcapfab/key.pem') end
end


file '/var/log/pcapfab.log' do
  action :touch
  owner 'pcapfab'
  group 'pcapfab'
  mode '0644'
  not_if do ::File.exists?('/var/log/pcapfab.log') end
end

template '/etc/systemd/system/pcapfab.service' do
  source 'pcapfab.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

systemd_unit 'pcapfab.service' do
  action :enable
end

systemd_unit 'pcapfab.service' do
  action :start
end

