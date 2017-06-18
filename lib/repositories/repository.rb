require 'repositories/base'

module Repositories
  class Repository
    attr_reader :name, :ref, :branches

    def initialize(name, ref)
      @name = name
      @ref = ref
      @branches = []
    end
  end
end
