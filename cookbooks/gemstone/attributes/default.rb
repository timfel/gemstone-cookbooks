default[:gemstone][:user][:name]      = "glass"
default[:gemstone][:user][:uid]       = "1001"
default[:gemstone][:user][:home_dir]  = "/home/#{default[:user][:name]}"

# default[:gemstone][:timezone]         = "America/Los_Angeles"
default[:gemstone][:timezone]         = "MST"
default[:gemstone][:locale]           = "en_US.UTF-8"
default[:gemstone][:version]          = "25153"
# GemStone 2.4
# default[:gemstone][:version]          = "2.4.4.3"
# default[:gemstone][:platform]         = "x86_64.Linux"
# default[:gemstone][:url]              = "ftp://ftp.gemstone.com/pub/GemStone64/#{default[:gemstone][:version]}"
# default[:gemstone][:filename]         = "GemStone64Bit#{default[:gemstone][:version]}-#{default[:gemstone][:platform]}.zip"
# GemStone 3.0
default[:gemstone][:url]              = "http://glass-downloads.gemstone.com/maglev"
default[:gemstone][:version]          = "25153"
default[:gemstone][:platform]         = "Linux-x86_64"
default[:gemstone][:filename]         = "GemStone-#{default[:gemstone][:version]}.#{node[:gemstone][:platform]}"
