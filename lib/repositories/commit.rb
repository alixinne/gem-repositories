require 'repositories/base'

require 'date'

module Repositories
  class Commit
    attr_reader :sha, :author, :date, :repository

    def initialize(sha, author, date, repository)
      @sha = sha
      @author = author
      begin
        @date = date.is_a?(String) ? DateTime.strptime(date) : date
      rescue
        # in case default date parsing fails
        begin
          @date = DateTime.strptime(date, "%FT%T.%L%:z")
        rescue => e
          raise "Failed to parse #{date}"
        end
      end
      @repository = repository
    end

    def to_yaml_properties
      %i[@sha @author @date]
    end
  end
end
