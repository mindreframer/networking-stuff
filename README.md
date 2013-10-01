# Puppet module: tinc

This is a Puppet module for tinc based on the second generation layout ("NextGen") of Example42 Puppet Modules.

Made by Alessandro Franceschi / Lab42

Official site: http://www.example42.com

Official git repository: http://github.com/example42/puppet-tinc

Released under the terms of Apache 2 License.

This module requires functions provided by the Example42 Puppi module (you need it even if you don't use and install Puppi)

For detailed info about the logic and usage patterns of Example42 modules check the DOCS directory on Example42 main modules set.

## USAGE - Basic management

* Install tinc with default settings

        class { 'tinc': }

* Install a specific version of tinc package

        class { 'tinc':
          version => '1.0.1',
        }

* Disable tinc service.

        class { 'tinc':
          disable => true
        }

* Remove tinc package

        class { 'tinc':
          absent => true
        }

* Enable auditing without without making changes on existing tinc configuration files

        class { 'tinc':
          audit_only => true
        }


## USAGE - Overrides and Customizations
* Use custom sources for main config file 

        class { 'tinc':
          source => [ "puppet:///modules/lab42/tinc/tinc.conf-${hostname}" , "puppet:///modules/lab42/tinc/tinc.conf" ], 
        }


* Use custom source directory for the whole configuration dir

        class { 'tinc':
          source_dir       => 'puppet:///modules/lab42/tinc/conf/',
          source_dir_purge => false, # Set to true to purge any existing file not present in $source_dir
        }

* Use custom template for main config file. Note that template and source arguments are alternative. 

        class { 'tinc':
          template => 'example42/tinc/tinc.conf.erb',
        }

* Automatically include a custom subclass

        class { 'tinc':
          my_class => 'tinc::example42',
        }


## USAGE - Example42 extensions management 
* Activate puppi (recommended, but disabled by default)

        class { 'tinc':
          puppi    => true,
        }

* Activate puppi and use a custom puppi_helper template (to be provided separately with a puppi::helper define ) to customize the output of puppi commands 

        class { 'tinc':
          puppi        => true,
          puppi_helper => 'myhelper', 
        }

* Activate automatic monitoring (recommended, but disabled by default). This option requires the usage of Example42 monitor and relevant monitor tools modules

        class { 'tinc':
          monitor      => true,
          monitor_tool => [ 'nagios' , 'monit' , 'munin' ],
        }

* Activate automatic firewalling. This option requires the usage of Example42 firewall and relevant firewall tools modules

        class { 'tinc':       
          firewall      => true,
          firewall_tool => 'iptables',
          firewall_src  => '10.42.0.0/24',
          firewall_dst  => $ipaddress_eth0,
        }


[![Build Status](https://travis-ci.org/example42/puppet-tinc.png?branch=master)](https://travis-ci.org/example42/puppet-tinc)

[![Build Status](https://travis-ci.org/example42/puppet-tinc.png?branch=master)](https://travis-ci.org/example42/puppet-tinc)
