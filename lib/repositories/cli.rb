require 'repositories/base'
require 'repositories/host_config'

require 'fileutils'
require 'yaml'
require 'optparse'
require 'ostruct'

module Repositories
  module CLI
    def self.parse(argv)
      options = OpenStruct.new
      options.hosts = 'hosts.yml'
      options.force = false

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: repupdate [options]"

        opts.on("-h", "--hosts [PATH]", "Host config file") do |hosts|
          options.hosts = hosts
        end

        opts.on("-f", "--force", "Force push to backup repositories") do
          options.force = true
        end
      end
      opt_parser.parse!(argv)
      options
    end

    def self.run(argv)
      # Parse options
      options = parse(argv)

      # Load config for Git hosts
      hc = HostConfig.load(options.hosts)

      # Build a hash of all repositories
      host_repositories = hr(hc)

      # Check all source repositories
      named_repositories = Hash.new { |hash, key| hash[key] = [] }

      hc.hosts_by_use[:source].each do |host|
        host_repositories[host.name].each do |rep|
          named_repositories[rep.normalized_name] << rep
        end
      end

      # From named_repositories, determine source repositories to clone to
      # backup hosts depending on most recent commits
      source_repositories = {}

      named_repositories.each do |nn, reps|
        ref_rep = reps[0]
        unmatch_count = 0

        if reps.length > 1
          reps.drop(1).each do |other_rep|
            diff_state = ref_rep.find_differences(other_rep)
            print_diff_state(ref_rep, other_rep, diff_state) do
              unmatch_count += 1
            end
          end
        end

        if unmatch_count
          ref_rep = reps.max_by { |rep| rep.most_recent_head.date }
          STDERR.puts "On #{ref_rep.name}: differences were found between "\
                      "source repositories. Using #{ref_rep.host.name} as a "\
                      "source."
        else
          STDERR.puts "All source repositories for #{ref_rep.name} are at the "\
                      "same revision."
        end

        source_repositories[nn] = ref_rep
      end

      # Check that all named repositories have an equivalent in all backups
      exit_code = 0

      source_repositories.each do |_nn, rep|
        hc.hosts_by_use[:backup].each do |backup_host|
          backup_rep = host_repositories[backup_host.name].find { |br| br.normalized_name == nn }

          source_ssh = rep.ssh_url
          target_ssh = nil

          should_update = false

          if backup_rep
            # Found a matching backup repository on backup host
            diff_state = rep.find_differences(backup_rep)
            target_ssh = backup_rep.ssh_url

            print_diff_state(rep, backup_rep, diff_state) do
              should_update = true
            end
          else
            # Found no matching backup repository
            STDERR.puts "#{rep.name} is missing from #{backup_host.name}"
            should_update = true

            # Create repository
            STDERR.print "Creating repository... "
            target_ssh = backup_host.create_repository(rep.name)
            STDERR.puts "completed at #{target_ssh}"
          end

          next unless should_update
          STDERR.puts "Updating #{rep.name} on #{backup_host.name}"

          STDERR.puts "Cloning source repository"
          if doexec(["git", "clone", "--bare", source_ssh, "working.git"])
            Dir.chdir "working.git" do
              STDERR.puts "Mirroring to target repository"
              cmd = ["git", "push", "--mirror"]
              cmd << "--force" if options.force
              cmd << target_ssh

              if doexec(cmd)
                STDERR.puts "Completed!"
              else
                STDERR.puts "Failed!"
                exit_code = 1
              end
            end
          else
            STDERR.puts "Cloning source repository failed!"
            exit_code = 1
          end

          if Dir.exist? "working.git"
            STDERR.puts "Cleaning working.git directory"
            FileUtils.rmtree("working.git", secure: true)
          end
        end
      end

      exit_code # success
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
      return if state.empty?

      STDERR.puts "On #{ref.name}: differing branch state between "\
                  "#{ref.host.name} and #{other.host.name}"
      STDERR.puts YAML.dump(differences: state)
      yield if block_given?
    end
  end
end
