# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "vagrant-systemd"
  s.version = "0.3.1"
  s.authors = ["Benedikt Böhm"]
  s.email = ["bb@xnull.de"]
  s.homepage = "http://github.com/zentoo/vagrant-systemd"
  s.summary = %q{Vagrant plugin to detect and support Systemd based systems}
  s.description = %q{Vagrant plugin to detect and support Systemd based systems}

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths    = ["lib"]
end
