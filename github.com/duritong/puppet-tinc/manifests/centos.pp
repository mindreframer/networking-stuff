class tinc::centos inherits tinc::base {
  file {
    '/etc/sysconfig/tinc' :
      source => ["puppet:///modules/site_tinc/CentOS/${::fqdn}/tinc.sysconfig",
      "puppet:///modules/site_tinc/tinc.sysconfig",
      "puppet:///modules/tinc/${::operatingsystem}/tinc.sysconfig"],
      require => Package['tinc'],
      notify => Service['tinc'],
      owner => root,
      group => 0,
      mode => 0644 ;
  }
  Service['tinc'] {
    hasstatus => true,
    hasrestart => true
  }
}
