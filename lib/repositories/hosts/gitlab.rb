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
          Enumerator.new do |yielder|
            ::Gitlab.projects(owned: true).auto_paginate.each do |repo|
              next unless matches(repo.name)

              begin
                yielder << Repository.new(repo.name, repo, repo.ssh_url_to_repo, self) do |r, branches|
                  ::Gitlab.branches(repo.id).auto_paginate.each do |bran|
                    branches << Branch.new(bran.name,
                                           Commit.new(bran.commit.id,
                                                      "#{bran.commit.author_name} <#{bran.commit.author_email}>",
                                                      bran.commit.authored_date,
                                                      r),
                                           r)
                  end
                end
              rescue => e
                puts "Could not fetch #{repo.name}, it may not belong to us: #{e}"
              end
            end
          end
        end
      end

      def create_repository(name)
        with_gitlab do
          rep = ::Gitlab.create_project(name,
                                        default_branch: 'master',
                                        wiki_enabled: 0,
                                        wall_enabled: 0,
                                        issues_enabled: 0,
                                        snippets_enabled: 0,
                                        merge_requests_enabled: 0,
                                        jobs_enabled: 0,
                                        public: 0)

          Repository.new(rep.name, rep, rep.ssh_url_to_repo, self)
        end
      end

      def on_push(repository)
        STDERR.puts "Pushing to GitLab repository #{repository.name}"

        repo = repository.ref
        protected_branches = []

        begin
          ::Gitlab.branches(repo.id).auto_paginate.each do |bran|
            if bran.protected
              STDERR.puts "  Unprotecting branch #{bran.name}"
              ::Gitlab.unprotect_branch(repo.id, bran.name)
              protected_branches << bran.name
            end
          end

          return yield
        ensure
          protected_branches.each do |bran_name|
            STDERR.puts "  Protecting back branch #{bran_name}"
            ::Gitlab.protect_branch(repo.id, bran_name)
          end
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
