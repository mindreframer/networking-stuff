Puppet::Parser::Functions::newfunction(:tinc_keygen, :type => :rvalue, :doc =>
  "Returns an array containing the tinc private and public (in this order) key
  for a certain private key path.
  It will generate the keypair if both do not exist. It will also generate
  the directory hierarchy if required.
  It accepts only fully qualified paths, everything else will fail.") do |args|
    raise Puppet::ParseError, "Wrong number of arguments" if args.to_a.length < 1 || args.to_a.length > 2
    name = args.to_a[0]
    if args.to_a.length > 1
      dir = args.to_a[1]
      raise Puppet::ParseError, "Only fully qualified paths are accepted (#{dir})" unless dir =~ /^\/.+/
    else
      dir = File.join('/etc/tinc',name)
    end
    private_key_path = File.join(dir,"rsa_key.priv")
    public_key_path = File.join(dir,"rsa_key.pub")
    raise Puppet::ParseError, "Either only the private or only the public key exists" if File.exists?(private_key_path) ^ File.exists?(public_key_path)
    [private_key_path,public_key_path].each do |path|
      raise Puppet::ParseError, "#{path} is a directory" if File.directory?(path)
    end

    unless File.directory?(dir)
      require 'fileutils'
      FileUtils.mkdir_p(dir, :mode => 0700)
    end
    unless [private_key_path,public_key_path].all?{|path| File.exists?(path) }
      output = Puppet::Util.execute(['/usr/sbin/tincd', '-c', dir, '-n', name, '-K'])
      raise Puppet::ParseError, "Something went wrong during key generation! Output: #{output}" unless output =~ /Generating .* bits keys/
    end
    [File.read(private_key_path),File.read(public_key_path)]
end
