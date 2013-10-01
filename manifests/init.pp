class tinc(
  $manage_shorewall = false
) {
  require bridge_utils
  case $::operatingsystem {
    centos: { include tinc::centos }
    debian: { include tinc::debian }
    default: { include tinc::base }
  }
  if $manage_shorewall {
    include shorewall::rules::tinc
  }
}
