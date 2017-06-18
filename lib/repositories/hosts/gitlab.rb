require 'repositories/base'
require 'repositories/hosts/base'

require 'repositories/commit'
require 'repositories/branch'
require 'repositories/repository'

require 'gitlab'

module Repositories
  module Hosts
    class Gitlab < Base
      def initialize(config)
        super(config)

        ::Gitlab.configure do |c|
          c.endpoint = @base
          c.private_token = @token
        end
      end

      def repositories
        ::Gitlab.projects.auto_paginate.collect do |repo|
          r = Repository.new(repo.name, repo)

          ::Gitlab.branches(repo.id).auto_paginate.each do |bran|
            r.branches << Branch.new(bran.name,
                                     Commit.new(bran.commit.id,
                                                "#{bran.commit.author_name} <#{bran.commit.author_email}>",
                                                bran.commit.authored_date,
                                                r),
                                     r)
          end

          r
        end
      end
    end
  end
end
