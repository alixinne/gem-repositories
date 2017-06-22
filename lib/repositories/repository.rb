require 'repositories/base'

module Repositories
  class Repository
    attr_reader :name, :ref, :branches

    def initialize(name, ref)
      @name = name
      @ref = ref
      @branches = []
    end

    def normalized_name
      name.downcase
    end

    def to_yaml_properties
      [:@name, :@branches]
    end
  end
end
