class tinc::puppetmaster($tinc_storage_path){
  file{$tinc_storage_path:
    ensure => directory,
    owner => root, group => puppet, mode => '0660';
  }

  File_line<<| tag == 'tinc_hosts_file' |>>
}
