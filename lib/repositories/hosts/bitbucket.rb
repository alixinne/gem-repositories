require 'repositories/base'
require 'repositories/hosts/base'

require 'repositories/commit'
require 'repositories/branch'
require 'repositories/repository'

require 'bitbucket_rest_api'

module Repositories
  module Hosts
    class Bitbucket < Base
      def initialize(config)
        super(config)

        @bitbucket = ::BitBucket.new login: @username, password: @token
      end

      def repositories
        Enumerator.new do |yielder|
          @bitbucket.repos.list.each do |repo|
            next unless matches(repo.name)

            ssh_url = "git@bitbucket.org:#{repo.owner}/#{repo.slug}.git"
            web_url = "https://bitbucket.org/#{repo.owner}/#{repo.slug}"
            yielder << Repository.new(repo.name, repo.description, repo, ssh_url, web_url, self) do |r, branches|
              @bitbucket.repos.branches(repo.owner, repo.slug) do |name, _bran|
                response = []
                @bitbucket.repos.commits.list(repo.owner, repo.slug, name).each do |item|
                  response << item
                end
                comm = response[1][1][0]

                c = Commit.new(comm['hash'], comm.author.raw, comm['date'], r)
                branches << Branch.new(name, c, r)
              end
            end
          end
        end
      end
    end
  end
end
