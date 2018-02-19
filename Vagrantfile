# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 1.6.0"

require 'yaml'

boxes = YAML.load_file('./boxes.yaml')
common = YAML.load_file('./puppet/hieradata/common.yaml')
puppet_run = (common['orautils_nodemanagerautostart_enabled']) ? "once" : "always"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "admin" , primary: true do |admin|

    admin.vm.box = boxes['virtualbox.box']
    admin.vm.box_url = boxes['virtualbox.box_url']

    admin.vm.provider :vmware_fusion do |v, override|
      override.vm.box = boxes['vmware.box']
      override.vm.box_url = boxes['vmware.box_url']
    end

    admin.vm.hostname = "admin.example.com"
    admin.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    admin.vm.synced_folder "/Users/edwinbiemond/software", "/software"

    admin.vm.network :private_network, ip: "10.10.10.10"

    admin.vb.memory = 2512
    admin.vb.cpus = 2

    admin.vm.provision :shell, path: "./puppet_config.sh"

    # in order to enable this shared folder, execute first the following in the host machine: mkdir log_puppet_weblogic && chmod a+rwx log_puppet_weblogic
    #admin.vm.synced_folder "./log_puppet_weblogic", "/tmp/log_puppet_weblogic", :mount_options => ["dmode=777","fmode=777"]

    admin.vm.provision "puppet", run: puppet_run do |puppet|
      puppet.environment_path     = "puppet/environments"
      puppet.environment          = "development"

      puppet.manifests_path       = "puppet/environments/development/manifests"
      puppet.manifest_file        = "site.pp"

      puppet.options           = [
                                  '--verbose',
                                  '--report',
                                  '--trace',
                                  # '--debug',
#                                  '--parser future',
                                  '--strict_variables',
                                  '--hiera_config /vagrant/puppet/hiera.yaml'
                                 ]
      puppet.facter = {
        "environment"     => "development",
        "vm_type"         => "vagrant",
      }

    end

  end

  config.vm.define "node1" do |node1|

    node1.vm.box = boxes['virtualbox.box']
    node1.vm.box_url = boxes['virtualbox.box_url']

    node1.vm.provider :vmware_fusion do |v, override|
      override.vm.box = boxes['vmware.box']
      override.vm.box_url = boxes['vmware.box_url']
    end

    node1.vm.hostname = "node1.example.com"
    node1.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    node1.vm.synced_folder "/Users/edwinbiemond/software", "/software"

    node1.vm.network :private_network, ip: "10.10.10.100"

    node1.vm.provider.memory = 2512

    node1.vm.provision :shell, path: "./puppet_config.sh"

    node1.vm.provision "puppet", run: puppet_run do |puppet|

      puppet.environment_path  = "puppet/environments"
      puppet.environment       = "development"

      puppet.manifests_path    = "puppet/environments/development/manifests"
      puppet.manifest_file     = "node.pp"

      puppet.options           = [
                                  '--verbose',
                                  '--report',
                                  '--trace',
#                                  '--debug',
#                                  '--parser future',
                                  '--strict_variables',
                                  '--hiera_config /vagrant/puppet/hiera.yaml'
                                 ]
      puppet.facter = {
        "environment"     => "development",
        "vm_type"         => "vagrant",
      }

    end

  end

  config.vm.define "node2" do |node2|

    node2.vm.box = boxes['virtualbox.box']
    node2.vm.box_url = boxes['virtualbox.box_url']

    node2.vm.provider :vmware_fusion do |v, override|
      override.vm.box = boxes['vmware.box']
      override.vm.box_url = boxes['vmware.box_url']
    end

    node2.vm.hostname = "node2.example.com"
    node2.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    node2.vm.synced_folder "/Users/edwinbiemond/software", "/software"

    node2.vm.network :private_network, ip: "10.10.10.200", auto_correct: true

    node2.vm.provider.memory = 2512

    node2.vm.provision :shell, path: "./puppet_config.sh"

    node2.vm.provision "puppet", run: puppet_run do |puppet|

      puppet.environment_path  = "puppet/environments"
      puppet.environment       = "development"

      puppet.manifests_path    = "puppet/environments/development/manifests"
      puppet.manifest_file     = "node.pp"

      puppet.options           = [
                                  '--verbose',
                                  '--report',
                                  '--trace',
#                                  '--debug',
#                                  '--parser future',
                                  '--strict_variables',
                                  '--hiera_config /vagrant/puppet/hiera.yaml'
                                 ]
      puppet.facter = {
        "environment"     => "development",
        "vm_type"         => "vagrant",
      }

    end
  end
end
