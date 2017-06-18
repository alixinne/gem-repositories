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
  end
end
