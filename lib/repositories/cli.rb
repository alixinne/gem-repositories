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

      had_difference = false
      named_repositories.each do |nn, reps|
        if reps.length > 1
          ref_rep = reps[0]
          reps.drop(1).each do |other_rep|
            diff_state = ref_rep.find_differences(other_rep)

            if diff_state.length > 0
              puts "On #{ref_rep.name}: differing branch state between #{ref_rep.host.type} and #{other_rep.host.type}"
              puts YAML.dump({ diferences: diff_state })
              had_difference = true
            end
          end
        end
      end

      if had_difference
        puts "Differences were found between source repositories, cannot continue."
        return
      end

      # Check that all named repositories have an equivalent in all backup repositories
      # TODO
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
