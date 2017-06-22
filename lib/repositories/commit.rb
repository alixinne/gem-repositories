require 'repositories/base'

module Repositories
  class Commit
    attr_reader :sha, :author, :date, :repository

    def initialize(sha, author, date, repository)
      @sha = sha
      @author = author
      @date = date
      @repository = repository
    end

    def to_yaml_properties
      [:@sha, :@author, :@date]
    end
  end
end
