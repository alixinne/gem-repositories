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
                  yielder << Repository.new(repo['name'], repo['description'], repo, repo['ssh_url'], repo['html_url'], self) do |r, branches|
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

      def create_repository(name, description = '')
        RestClient.post "#{@base}/user/repos", {
          'auto_init' => false,
          'description' => description,
          'name' => name,
          'private' => true
        }.to_json,
        params: { access_token: @token },
        content_type: :json,
        accept: :json do |response, _request, _result|
          case response.code
          when 201
            begin
              parsed = JSON.parse(response.body)
              Repository.new(parsed['name'], parsed['description'], parsed, parsed['ssh_url'], parsed['html_url'], self)
            rescue JSON::UnparserError => e
              raise "Failed to parse response to repo creation: #{e}"
            end
          else
            raise "Failed to create repository: #{response}"
          end
        end
      end

      def update_description(repository, description)
        RestClient.put "#{@base}/user/repos", {
          'description' => description
        }.to_json,
        params: { access_token: @token },
        content_type: :json,
        accept: :json do |_response, _request, _result|
        end
      end

      def on_push(_repository)
        # nothing to do on Gitea
        yield
      end
    end
  end
end
