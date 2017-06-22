require 'repositories/base'
require 'repositories/host_config'

require 'yaml'

module Repositories
  module CLI
    def self.run(argv)
      # Load config for Git hosts
      hc = HostConfig.load(argv.first || 'hosts.yml')

      # Build a hash of all repositories
      host_repositories = self.hr(hc)
      File.write('repositories.yml', host_repositories)

      # Check all source repositories
      named_repositories = Hash.new { |hash, key| hash[key] = [] }

      hc.hosts_by_use[:source].each do |host|
        host_repositories[host.type].each do |rep|
          array = named_repositories[rep.normalized_name]
          puts "Adding one instance of #{rep.name} (#{host.type}) to #{array.length} existing"
          array << rep
        end
      end

      # For all repositories that have multiple instances
      # Ensure they all have the same state
      named_repositories.each do |nn, reps|
        if reps.length > 1
          differing_branch_state = false

          if reps.all? { |r| r.branches.length == reps[0].branches.length }
            # All repositories have the same branches
            ref_rep = reps[0]
            reps.drop(1).each do |rep|
              # Check that all branches have a match in the reference repository
              rep.branches.each do |bran|
                # Find matching reference branch
                ref_bran = ref_rep.branches.find { |refb| refb.name == bran.name }

                if ref_bran
                  # Matching branch found
                  if ref_bran.head_commit.sha != bran.head_commit.sha
                    differing_branch_state = true
                    break
                  end
                else
                  # No matching branch
                  differing_branch_state = true
                  break
                end
              end

              break if differing_branch_state
            end
          else
            differing_branch_state = true
          end

          if differing_branch_state
            puts "On #{reps[0].name}: differing branch state"
            puts YAML.dump(reps)
          end
        end
      end
    end

    def self.hr(hc)
      reps = {}

      hc.hosts.each do |type, host|
        puts "Fetching #{type} repositories..."
        reps[type] = host.repositories
      end

      reps
    end
  end
end
