class tinc::debian inherits tinc::base {
  Service['tinc'] {
    hasstatus => false,
    pattern => 'tincd',
    hasrestart => true
  }
}
