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
        i_forks = { 'include_forks' => [] }.merge(config)['include_forks']

        if i_forks.is_a? Array
          @include_forks = Set.new(i_forks)
        else
          @include_forks = if i_forks then true else false end
        end

        @github = ::Github.new basic_auth: "#{@user}:#{@token}",
                               auto_pagination: true
      end

      def include_forks?
        @include_forks
      end

      def should_include_fork?(repo)
        if repo.fork
          if @include_forks == false
            return false
          end

          return @include_forks.include? repo.name
        end

        true
      end

      def repositories
        Enumerator.new do |yielder|
          @github.repos.list.each do |repo|
            next unless matches(Repository.to_rep_name(repo.name))
            next unless should_include_fork?(repo)

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
