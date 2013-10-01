# Define: tinc::tunnel
#
# Manages tinc tunnels
#
# Parameters:
#
# [*mode*]
#   Sets general tinc mode: router|switch|hub. Default: router
#
# [*connect_to*]
#   An array of servers to connect to.
#
# [*device*]
#   Device Type. Default: tun
#
# [*auth_type*]
#   Authentication method: key, tls-server, tls-client
#
# [*auth_key*]
#   Source of the key file (Used when auth_type = key)
#   Used as: source => $auth_key
#   So it should be something like:
#   puppet:///modules/example42/tinc/mykey
#   Can be also an array
#
# [*dev*]
#   Device: tun for Ip routing , tap for bridging mode
#   Default: tun
#
# [*server*]
#   Server parameter. (in server mode)
#
# [*route*]
#   Route parameter
#
# [*push*]
#   Push parameter
#
# [*template*]
#   Template to be used for the tunnel configuration.
#   Default is tinc/tunnel.conf.erb
#   File: tinc/templates/tunnel.conf.erb
#
# [*enable*]
#   If the tunnel is enabled or not.
#
define tinc::tunnel (
  $auth_type    = 'tls-server',
  $mode         = 'server',
  $remote       = '',
  $port         = '1194',
  $auth_key     = '',
  $proto        = 'tcp',
  $dev          = 'tun',
  $server       = '10.8.0.0 255.255.255.0',
  $route        = '',
  $push         = '',
  $template     = '',
  $enable       = true ) {

  include tinc

  $bool_enable=any2bool($enable)

  $manage_file = $bool_enable ? {
    true    => 'present',
    default => 'absent',
  }

  $real_proto = $proto ? {
    udp => 'udp',
    tcp => $mode ? {
      'server' => 'tcp-server',
      'client' => 'tcp-client',
    },
  }

  $real_template = $template ? {
    ''      => $mode ? {
      'server' => 'tinc/server.conf.erb',
      'client' => 'tinc/client.conf.erb',
    },
    default => $template,
  }

  file { "tinc_${name}.conf":
    ensure  => $manage_file,
    path    => "${tinc::config_dir}/${name}.conf",
    mode    => $tinc::config_file_mode,
    owner   => $tinc::config_file_owner,
    group   => $tinc::config_file_group,
    require => Package['tinc'],
    notify  => Service['tinc'],
    content => template($real_template),
  }

  if $auth_key != '' {
    file { "tinc_${name}.key":
      ensure  => $manage_file,
      path    => "${tinc::config_dir}/${name}.key",
      mode    => '0600',
      owner   => $tinc::process_user,
      group   => $tinc::process_user,
      require => Package['tinc'],
      notify  => Service['tinc'],
      source  => $auth_key,
    }
  }

# Automatic monitoring of port and service
  if $tinc::bool_monitor == true {

    $target = $remote ? {
      ''      => $tinc::monitor_target,
      default => $remote,
    }

    monitor::port { "tinc_${name}_${proto}_${port}":
      enable   => $bool_enable,
      protocol => $proto,
      port     => $port,
      target   => $target,
      tool     => $tinc::monitor_tool,
    }
    monitor::process { "tinc_${name}_process":
      enable   => $bool_enable,
      process  => $tinc::process,
      service  => $tinc::service,
      pidfile  => "${tinc::pid_file}/${name}.pid",
      user     => $tinc::process_user,
      argument => "${name}.conf",
      tool     => $tinc::monitor_tool,
    }
  }

# Automatic Firewalling
  if $tinc::bool_firewall == true {
    firewall { "tinc_${name}_${proto}_${port}":
      source      => $tinc::firewall_source_real,
      destination => $tinc::firewall_destination_real,
      protocol    => $proto,
      port        => $port,
      action      => 'allow',
      direction   => 'input',
      enable      => $bool_enable,
    }
  }

}
