require 'repositories/base'

require 'date'

module Repositories
  class Commit
    attr_reader :sha, :author, :date, :repository

    def initialize(sha, author, date, repository)
      @sha = sha
      @author = author
      @date = date.is_a? String ? DateTime.strptime(date) : date
      @repository = repository
    end

    def to_yaml_properties
      %i[@sha @author @date]
    end
  end
end
