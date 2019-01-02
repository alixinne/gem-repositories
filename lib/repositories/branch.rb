require 'repositories/base'

module Repositories
  class Branch
    attr_reader :name, :head_commit, :repository

    def initialize(name, head_commit, repository)
      @name = name
      @head_commit = head_commit
      @repository = repository
    end

    def to_yaml_properties
      %i[@name @head_commit]
    end
  end
end
