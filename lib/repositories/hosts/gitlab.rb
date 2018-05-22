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
      end

      def repositories
        with_gitlab do
          repos = []

          ::Gitlab.projects(owned: true).auto_paginate.each do |repo|
            next unless matches(repo.name)

            begin
              r = Repository.new(repo.name, repo, repo.ssh_url_to_repo, self)

              ::Gitlab.branches(repo.id).auto_paginate.each do |bran|
                r.branches << Branch.new(bran.name,
                                         Commit.new(bran.commit.id,
                                                    "#{bran.commit.author_name} <#{bran.commit.author_email}>",
                                                    bran.commit.authored_date,
                                                    r),
                                         r)
              end

              repos << r
            rescue => e
              puts "Could not fetch #{repo.name}, it may not belong to us: #{e}"
            end
          end

          repos
        end
      end

      def create_repository(name)
        with_gitlab do
          ::Gitlab.create_project(name,
                                  default_branch: 'master',
                                  wiki_enabled: 0,
                                  wall_enabled: 0,
                                  issues_enabled: 0,
                                  snippets_enabled: 0,
                                  merge_requests_enabled: 0,
                                  public: 0).ssh_url_to_repo
        end
      end

      private

      def with_gitlab
        ::Gitlab.configure do |c|
          c.endpoint = @base
          c.private_token = @token
        end

        @user_id = ::Gitlab.user.id

        yield
      end
    end
  end
end
