%w[ xauth libgl1-mesa-dev ia32-libs ].each{ |pkg| package pkg }

# bash "Enable X11 forwarding" do
#   user "root"
#   code "echo 'kernel.shmmax = 209715200 # 200 MB for GemStone' >> /etc/sysctl.conf"
#   not_if "grep -q 'GemStone' /etc/sysctl.conf"
# end

username = node[:gemstone][:user][:name]

gemtools_file = node[:gemstone][:gemtools_file]
gemtools_folder = node[:gemstone][:gemtools_folder]
# gemtools_file = "GemTools-2.4.4.3.app"

bash "Download GemTools" do
  remote_file = "http://seaside.gemstone.com/squeak/#{gemtools_file}"

  # Hosted on JohnnyT's rackspace account - has Seaside30 loaded
  # remote_file = "http://c0084442.cdn2.cloudfiles.rackspacecloud.com/#{gemtools_file}.zip"

  cwd "/opt/gemstone"
  code "wget #{remote_file}"
  not_if "[ -e /opt/gemstone/#{gemtools_file} ]"
end

bash "Install GemTools" do
  cwd "/opt/gemstone"
  code <<-EOH
    unzip #{gemtools_file}
    ln -s #{gemtools_folder} gemtools
    cp #{gemtools_folder}/#{node[:gemstone][:gemtools_sh]} #{gemtools_folder}/GemTools.sh
    chmod a+x #{gemtools_folder}/GemTools.sh
    chown -R #{username}:#{username} #{gemtools_folder}
    chmod -R o-w #{gemtools_folder}
  EOH

  not_if "[ -e /opt/gemstone/gemtools ]"
end

cookbook_file "/usr/local/bin/gemtools" do
  source  "gemtools"
  # owner   username
  # group   username
  mode    0755
  action  :create_if_missing
end
