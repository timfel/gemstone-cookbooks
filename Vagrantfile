#!/usr/bin/ruby

Vagrant::Config.run do |config|
  config.vm.box_url = "http://files.vagrantup.com/lucid64.box"
  config.vm.box = "lucid64"
  config.vm.forward_port "http", 80, 8888
  config.vm.customize do |vm|
    vm.memory_size = 1024
  end

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.roles_path = "roles"
    chef.add_role "gemstone"

    # # These are all included in the default gemstone role
    # config.chef.add_recipe "gemstone"
    # config.chef.add_recipe "gemstone::services"
    # config.chef.add_recipe "gemstone::remote"
    # config.chef.add_recipe "gemstone::nginx"
  end
end
