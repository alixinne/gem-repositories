require 'repositories/base'
require 'repositories/host_config'

require 'fileutils'
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
        host_repositories[host.name].each do |rep|
          array = named_repositories[rep.normalized_name]
          STDERR.puts "Adding one instance of #{rep.name} (#{host.name}) to #{array.length} existing"
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
          backup_rep = host_repositories[backup_host.name].find { |br| br.normalized_name == nn}

          source_ssh = rep.ssh_url
          target_ssh = nil

          should_update = false

          if backup_rep
            # Found a matching backup repository on backup host
            diff_state = rep.find_differences(backup_rep)
            target_ssh = backup_rep.ssh_url

            print_diff_state(rep, backup_rep, diff_state) do
              had_difference = true
              should_update = true
            end
          else
            # Found no matching backup repository
            STDERR.puts "#{rep.name} is missing from #{backup_host.name}"
            had_difference = true
            should_update = true

            # Create repository
            STDERR.print "Creating repository... "
            target_ssh = backup_host.create_repository(rep.name)
            STDERR.puts "completed at #{target_ssh}"
          end

          if should_update
            STDERR.puts "Updating #{rep.name} on #{backup_host.name}"

            STDERR.puts "Cloning source repository"
            if doexec(["git", "clone", "--bare", source_ssh, "working.git"])
              Dir.chdir "working.git" do
                STDERR.puts "Mirroring to target repository"
                if doexec(["git", "push", "--mirror", target_ssh])
                  STDERR.puts "Completed!"
                else
                  STDERR.puts "Failed!"
                end
              end
            else
              STDERR.puts "Cloning source repository failed!"
            end

            if Dir.exists? "working.git"
              STDERR.puts "Cleaning working.git directory"
              FileUtils.rmtree("working.git", secure: true)
            end
          end
        end
      end

      return 0
    end

    def self.doexec(cmd)
      STDERR.puts(cmd.inspect)
      system(*cmd)
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
        STDERR.puts "On #{ref.name}: differing branch state between #{ref.host.name} and #{other.host.name}"
        STDERR.puts YAML.dump({ differences: state })
        yield if block_given?
      end
    end
  end
end
