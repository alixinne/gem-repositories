require 'repositories/base'
require 'repositories/hosts/bitbucket'
require 'repositories/hosts/github'
require 'repositories/hosts/gitlab'

module Repositories
  class HostConfig
    attr_reader :hosts

    def initialize(config)
      @hosts = config['hosts'].collect do |host|
        host_class = Repositories::Hosts.const_get(host['type'].capitalize)
        host_class.new(host)
      end
    end

    def self.load(path)
      self.new(YAML.load_file(path))
    end
  end
end
