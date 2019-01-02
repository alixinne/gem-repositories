require 'repositories/base'

module Repositories
  module Hosts
    class Base
      attr_reader :type, :use_as, :exclude, :name

      def initialize(config)
        @name = config['name'] || config['type'].to_s
        @base = config['base']
        @username = config['username']
        @token = config['token']
        @type = config['type'].downcase.to_sym
        @use_as = (config['use_as'] || 'source').downcase.to_sym
        @exclude = config['exclude'] || []
        @include = config['include']
      end

      def matches(rep_name)
        if not @include.nil?
          @include.include? rep_name
        elsif not @exclude.nil?
          !@exclude.include? rep_name
        else
          true
        end
      end

      def to_yaml_properties
        %i[@type @use_as @base]
      end
    end
  end
end
