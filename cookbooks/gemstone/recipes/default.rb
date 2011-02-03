# Installs GemStone on the server
# Most of this stuff came from one of the following:
#
# http://programminggems.wordpress.com/2010/01/12/slicehost-2/
# http://onsmalltalk.com/2010-10-30-installing-a-gemstone-seaside-server-on-ubuntu-10.10
# http://onsmalltalk.com/2010-10-23-faster-remote-gemstone

# Packages
# %w[ htop iftop tree psmisc w3m screen curl git-core subversion vim-nox zip ].each{ |pkg| package pkg }
%w[ vim-nox htop iftop tree psmisc w3m screen curl git-core zip ].each{ |pkg| package pkg }

require_recipe "sudoers"

username = node[:gemstone][:user][:name] 
home_dir = "/home/#{username}"

user username do
  home home_dir
  shell "/bin/bash"
end

group "sudo" do
  members username
  append true
end

%w[ bin env .ssh .vim ].each do |source_dir|
  local_dir = source_dir.to_s.gsub(".", "")

  remote_directory "#{home_dir}/#{source_dir}" do
    source  local_dir
    owner   username
    group   username
    mode    0700
    files_owner username
    files_group username
    files_mode  local_dir =~ /bin/ ? 0700 : 0600
  end
end

# You can setup your key in roles/gemstone.json
if (keys = (node[:accounts][username] || {})[:keys])
  template "#{home_dir}/.ssh/authorized_keys" do
    source  "authorized_keys.erb"
    mode    "0600"
    owner   username
    group   username
    variables(:keys => keys)
  end
end

# Copy over dotfiles
%w[ bashrc profile screenrc topazini ].each do |dotfile|
  cookbook_file "#{home_dir}/.#{dotfile}" do
    source  dotfile
    owner   username
    group   username
    mode    0644
    action  :create_if_missing
  end
end


# glass home dir is owned by root???
bash "chown home dir" do
  code "chown #{username}:#{username} #{home_dir}"
  not_if "[ ! -O #{home_dir} ]"
end

#-----[ Main GemStone setup

# Use the setupSharedMemory script?
bash "Configure kernel for more shared memory" do
  user "root"
  code "echo 'kernel.shmmax = 786146304 # for GemStone' >> /etc/sysctl.conf"
  # code "echo 'kernel.shmmax = 209715200 # 200 MB for GemStone' >> /etc/sysctl.conf"
  not_if "grep -q 'GemStone' /etc/sysctl.conf"
end

bash "Set up timezone" do
  code <<-CMD
    mv /etc/localtime /etc/localtime.bak
    ln -sf /usr/share/zoneinfo/#{node[:gemstone][:timezone]} /etc/localtime
  CMD
  not_if "[ -e /etc/localtime.bak ]"
end

bash "Set the language and locale" do
  code <<-CMD
    locale-gen #{node[:gemstone][:locale]}
    /usr/sbin/update-locale LANG=#{node[:gemstone][:locale]}
  CMD
  not_if "echo $(locale) | grep -q 'LANG=#{node[:gemstone][:locale]}'"
end

bash "Setup a well-known port for GemStone client access" do
  user "root"
  code "echo 'gs64ldi 50377/tcp # GemStone/S 64 Bit' >> /etc/services"
  not_if "grep -q 'GemStone' /etc/services"
end

bash "Alias localhost to the glass appliance" do
  user "root"
  code "echo '127.0.0.1  glass' >> /etc/hosts"
  not_if "grep -q 'glass' /etc/hosts"
end

remote_directory "/opt/gemstone" do
  source        "gemstone"
  owner         username
  files_owner   username
end

zip_filename = node[:gemstone][:filename]

bash "Download GemStone" do
  cwd "/opt/gemstone"
  code "wget #{node[:gemstone][:url]}/#{node[:gemstone][:filename]}.tar.gz"
  not_if "[ -e /opt/gemstone/#{node[:gemstone][:filename]}.tar.gz ]"
end

bash "Install GemStone" do
  cwd "/opt/gemstone"
  code <<-EOH
    tar xzf #{node[:gemstone][:filename]}.tar.gz
    ln -s #{node[:gemstone][:filename]} productcp product/data/system.conf etc/
    mkdir -p data etc locks sys log www/glass1 www/glass2 www/glass3
    cp product/data/system.conf etc/
    cp product/seaside/etc/gemstone.key etc/
    cp product/seaside/etc/gemstone.key sys/
    cp product/bin/extent0.ruby.dbf data/extent0.dbf
    ln -s /opt/gemstone/product/bin/topaz /usr/local/bin/topaz
    touch log/seaside.log
    chmod +w data/extent0.dbf
    chmod ug+rw log/*
    chown -R #{username}: #{username} .
  EOH

  not_if "[ -e /opt/gemstone/data/extent0.dbf ]"
end


bash "Setup topaz" do
  cwd "/opt/gemstone/product/lib/"
  code <<-EOH
    for i in *; do ln -s $(pwd)/$i ../bin/$i; done
    ln -s /opt/gemstone/product/bin/topaz /usr/local/bin/topaz
  EOH

  not_if "[ -e /usr/local/bin/topaz ]"
end

# These get runSeasideGems30 working
%w[ runSeasideGems30 startSeaside30_Adaptor ].each do |filename|
  cookbook_file "/opt/gemstone/product/seaside/bin/#{filename}" do
    source  "gemstone/#{filename}"
    owner   username
    group   username
    mode    0755
    # action  :create_if_missing
  end
end

template "/opt/gemstone/product/seaside/defSeaside" do
  source  "defSeaside.erb"
  mode    "0444"
  owner   username
  group   username
end

# NOTE: the server needs to be rebooted before running this
# So, on first run, we only touch a marker file.
bash "Load lastest FastCGI" do
  cwd "/opt/gemstone/product/bin"
  code <<-CMD
if [[ ! -e /opt/gemstone/reboot_done ]]; then
  touch /opt/gemstone/reboot_done
else
topaz << EOF
run


ConfigurationOfGLASS updateServer.

Gofer new
    squeaksource: 'Seaside30';
    package: 'ConfigurationOfSeaside30';
    package: 'ConfigurationOfGrease';
    load.

GsDeployer deploy: [
    Gofer project load: 'Seaside30' version: '3.0.3.1' group: 'ALL'.
]


%
commit
logout
exit
EOF
touch /opt/gemstone/seaside_was_installed
fi
  CMD
  not_if "[ -e /opt/gemstone/seaside_was_installed ]"
end
