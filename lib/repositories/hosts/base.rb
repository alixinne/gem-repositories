require 'repositories/base'

module Repositories
  module Hosts
    class Base
      attr_reader :type, :use_as

      def initialize(config)
        @base = config['base']
        @username = config['username']
        @token = config['token']
        @type = config['type'].downcase.to_sym
        @use_as = config['use_as'].downcase.to_sym
      end
    end
  end
end
