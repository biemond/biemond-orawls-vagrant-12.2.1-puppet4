#!/usr/bin/env bash
ln -sf /vagrant/puppet/hiera.yaml /etc/puppetlabs/code/hiera.yaml;
rm -rf /etc/puppetlabs/code/modules;
ln -sf /vagrant/puppet/environments/development/modules /etc/puppetlabs/code/modules;
ln -sf /vagrant/software /
