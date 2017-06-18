require 'repositories/base'
require 'repositories/version'
require 'repositories/branch'
require 'repositories/commit'
require 'repositories/repository'
require 'repositories/host_config'
require 'repositories/cli'

module Repositories
  Hashie.logger = Logger.new('/dev/null')
end
