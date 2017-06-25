require 'repositories/base'
require 'repositories/hosts/bitbucket'
require 'repositories/hosts/github'
require 'repositories/hosts/gitlab'

module Repositories
  class HostConfig
    attr_reader :hosts, :hosts_by_use

    def initialize(config)
      @hosts_by_use = Hash.new { |hash, key| hash[key] = [] }
      @hosts = {}

      config['hosts'].each do |host|
        # Build host
        host_class = Repositories::Hosts.const_get(host['type'].capitalize)
        h = host_class.new(host)

        # Add to use hash
        @hosts_by_use[h.use_as] << h

        # Add to name hash
        @hosts[h.name] = h
      end
    end

    def self.load(path)
      self.new(YAML.load_file(path))
    end
  end
end
