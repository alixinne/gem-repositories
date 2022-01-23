# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'repositories/version'

Gem::Specification.new do |spec|
  spec.name          = "repositories"
  spec.version       = Repositories::VERSION
  spec.authors       = ["Vincent Tavernier"]
  spec.email         = ["vince.tavernier@gmail.com"]

  spec.summary       = %q{Repository multi-host management tool}
  spec.description   = %q{Manage the different versions of a same repository on different Git hosts.}
  #spec.homepage      = ""
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir.glob('**/*').reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.3"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "gitlab", "~> 4.8"
  spec.add_runtime_dependency "github_api", "~> 0.18"
  spec.add_runtime_dependency "rest-client", "~> 2.0"
end
