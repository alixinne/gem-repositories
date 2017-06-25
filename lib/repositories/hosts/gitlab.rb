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

        @user_id = ::Gitlab.user.id
      end

      def repositories
        ::Gitlab.projects.auto_paginate.collect do |repo|
          r = Repository.new(repo.name, repo, repo.ssh_url_to_repo, self)

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

      def create_repository(name)
        ::Gitlab.create_project(name, {
          default_branch: 'master',
          wiki_enabled: 0,
          wall_enabled: 0,
          issues_enabled: 0,
          snippets_enabled: 0,
          merge_requests_enabled: 0,
          public: 0,
          user_id: @user_id
        }).ssh_url_to_repo
      end
    end
  end
end
