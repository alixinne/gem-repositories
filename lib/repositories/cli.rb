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
          STDERR.puts "Adding one instance of #{rep.name} (#{host.type}) to #{array.length} existing"
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

            print_diff_state(ref_rep, other_rep, diff_state) do
              had_difference = true
            end
          end
        end
      end

      if had_difference
        STDERR.puts "Differences were found between source repositories, cannot continue."
        return 1
      end

      # Check that all named repositories have an equivalent in all backup repositories
      named_repositories.each do |nn, reps|
        # Use the first repository as a reference
        rep = reps[0]

        hc.hosts_by_use[:backup].each do |backup_host|
          backup_rep = host_repositories[backup_host.type].find { |br| br.normalized_name == nn}

          if backup_rep
            # Found a matching backup repository on backup host
            diff_state = rep.find_differences(backup_rep)

            print_diff_state(rep, backup_rep, diff_state) do
              had_difference = true
            end
          else
            # Found no matching backup repository
            STDERR.puts "#{rep.name} is missing from #{backup_host.type}"
          end
        end
      end

      if had_difference
        puts "Differences were found between backup and source repositories."
        return 2
      end

      return 0
    end

    def self.hr(hc)
      reps = {}

      hc.hosts.each do |type, host|
        STDERR.puts "Fetching #{type} repositories..."
        reps[type] = host.repositories
      end

      reps
    end

    def self.print_diff_state(ref, other, state)
      if state.length > 0
        STDERR.puts "On #{ref.name}: differing branch state between #{ref.host.type} and #{other.host.type}"
        STDERR.puts YAML.dump({ differences: state })
        yield if block_given?
      end
    end
  end
end
