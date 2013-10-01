# Class: tinc::params
#
# This class defines default parameters used by the main module class tinc
# Operating Systems differences in names and paths are addressed here
#
# == Variables
#
# Refer to tinc class for the variables defined here.
#
# == Usage
#
# This class is not intended to be used directly.
# It may be imported or inherited by other classes
#
class tinc::params {

  ### Module specific parameters
  $tinc_up_template = 'tinc/tinc-up.erb'

  # TEMP: We need to provide the init script on Centos
  $init_script_template = $::osfamily ? {
    RedHat  => 'tinc/init.redhat',
    default => undef,
  }
  $host_name = $::hostname
  $connect_to = ''
  $source_dir_hosts = ''
  $device = 'tun'
  $subnet = $network_eth0
  $template_hostfile = 'tinc/host.conf.erb'

  ### Application related parameters

  $package = $::operatingsystem ? {
    default => 'tinc',
  }

  $service = $::operatingsystem ? {
    default => 'tinc',
  }

  $service_status = $::operatingsystem ? {
    default => true,
  }

  $process = $::operatingsystem ? {
    default => 'tincd',
  }

  $process_args = $::operatingsystem ? {
    default => '',
  }

  $process_user = $::operatingsystem ? {
    default => 'tinc',
  }

  $config_dir = $::operatingsystem ? {
    default => '/etc/tinc',
  }

  $config_file = $::operatingsystem ? {
    default => '/etc/tinc/tinc.conf',
  }

  $config_file_mode = $::operatingsystem ? {
    default => '0644',
  }

  $config_file_owner = $::operatingsystem ? {
    default => 'root',
  }

  $config_file_group = $::operatingsystem ? {
    default => 'root',
  }

  $config_file_init = $::operatingsystem ? {
    /(?i:Debian|Ubuntu|Mint)/ => '/etc/default/tinc',
    default                   => '/etc/sysconfig/tinc',
  }

  $pid_file = $::operatingsystem ? {
    default => '/var/run/tinc.pid',
  }

  $data_dir = $::operatingsystem ? {
    default => '/etc/tinc',
  }

  $log_dir = $::operatingsystem ? {
    default => '/var/log/tinc',
  }

  $log_file = $::operatingsystem ? {
    default => '/var/log/tinc/tinc.log',
  }

  $port = '655'
  $protocol = 'tcp'

  # General Settings
  $my_class = ''
  $source = ''
  $source_dir = ''
  $source_dir_purge = false
  $template = 'tinc/tinc.conf.erb'
  $options = ''
  $service_autorestart = true
  $version = 'present'
  $absent = false
  $disable = false
  $disableboot = false

  ### General module variables that can have a site or per module default
  $monitor = false
  $monitor_tool = ''
  $monitor_target = $::ipaddress
  $firewall = false
  $firewall_tool = ''
  $firewall_src = '0.0.0.0/0'
  $firewall_dst = $::ipaddress
  $puppi = false
  $puppi_helper = 'standard'
  $debug = false
  $audit_only = false

}
