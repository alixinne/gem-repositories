require 'repositories/base'
require 'repositories/hosts/base'

require 'repositories/commit'
require 'repositories/branch'
require 'repositories/repository'

require 'ostruct'
require 'json'

require 'rest-client'

module Repositories
  module Hosts
    class Gitea < Base
      def repositories
        Enumerator.new do |yielder|
          RestClient.get "#{@base}/user/repos", { params: { access_token: @token }, accept: :json } do |response, request, result|
            case response.code
            when 200
              begin
                repos = JSON.parse(response.body)

                repos.each do |repo|
                  yielder << Repository.new(repo['name'], repo, repo['ssh_url'], self) do |r, branches|
                    RestClient.get "#{@base}/repos/#{repo['full_name']}/branches", { params: { access_token: @token }, accept: :json } do |response, request, result|
                      case response.code
                      when 200
                        begin
                          parsed_branches = JSON.parse(response.body)
                          parsed_branches.each do |parsed_branch|
                            c = Commit.new(parsed_branch['commit']['id'],
                                           "#{parsed_branch['commit']['author']['name']} <#{parsed_branch['commit']['author']['email']}>",
                                           parsed_branch['commit']['timestamp'],
                                           r)

                            branches << Branch.new(parsed_branch['name'], c, r)
                          end
                        rescue JSON::UnparserError => e
                          raise "Failed to parse branches for #{repo['full_name']}: #{e}"
                        end
                      else
                        raise "Failed to fetch branches information for #{repo['full_name']}"
                      end
                    end
                  end
                end
              rescue JSON::UnparserError => e
                raise "Failed to parse repository list: #{e}"
              end
            else
              raise "Failed to fetch user repositories: #{response}"
            end
          end
        end
      end
    end
  end
end
