require 'repositories/base'
require 'repositories/host_config'

require 'yaml'

module Repositories
  module CLI
    def self.run(argv)
      hc = HostConfig.load(argv.first || 'hosts.yml')

      File.write('detail.yml', YAML.dump(hc.hosts.select { |h| h.type == :bitbucket }.collect(&:repositories)))
    end
  end
end
