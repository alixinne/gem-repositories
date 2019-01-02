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

        @github = ::Github.new basic_auth: "#{@user}:#{@token}",
                               auto_pagination: true
      end

      def repositories
        Enumerator.new do |yielder|
          @github.repos.list.body.each do |repo|
            next unless matches(repo.name)

            r = Repository.new(repo.name, repo, repo.ssh_url, self)

            @github.repos.branches(repo.owner.login, repo.name).body.each do |bran|
              c = @github.repos.commits.get(repo.owner.login,
                                            repo.name,
                                            bran.commit.sha)

              r.branches << Branch.new(bran.name,
                                       Commit.new(c.sha,
                                                  "#{c.commit.author.name} <#{c.commit.author.email}>",
                                                  c.commit.author.date,
                                                  r),
                                       r)
            end

            yielder << r
          end
        end
      end
    end
  end
end
