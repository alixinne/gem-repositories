require 'repositories/base'
require 'repositories/hosts/base'

require 'repositories/commit'
require 'repositories/branch'
require 'repositories/repository'

require 'github_api'

module Repositories
  module Hosts
    class Github < Base
      def initialize(config)
        super(config)
        @include_forks = config.merge({ 'include_forks' => false })['include_forks']

        @github = ::Github.new basic_auth: "#{@user}:#{@token}",
                               auto_pagination: true
      end

      def include_forks?
        @include_forks
      end

      def repositories
        Enumerator.new do |yielder|
          @github.repos.list.each do |repo|
            next unless matches(repo.name)
            next if include_forks? ^ repo.fork

            yielder << Repository.new(repo.name, repo.description, repo, repo.ssh_url, repo.html_url, self) do |r, branches|
              @github.repos.branches.list(repo.owner.login, repo.name).each do |bran|
                c = @github.repos.commits.get(repo.owner.login,
                                              repo.name,
                                              bran.commit.sha)

                branches << Branch.new(bran.name,
                                       Commit.new(c.sha,
                                                  "#{c.commit.author.name} <#{c.commit.author.email}>",
                                                  c.commit.author.date,
                                                  r),
                                       r)
              end
            end
          end
        end
      end
    end
  end
end
