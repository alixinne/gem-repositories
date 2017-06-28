require 'repositories/base'

module Repositories
  module Actors
    class SSHUpdater
      def initialize(options)
        @options = options
      end

      def update(source_ssh, target_ssh)
        success = true

        Dir.mktmpdir do |tmpdir|
          STDERR.puts "Cloning source repository"
          target_dir = File.join(tmpdir, "working.git")
          if doexec(["git", "clone", "--bare", source_ssh, target_dir])
            Dir.chdir target_dir do
              STDERR.puts "Mirroring to target repository"
              cmd = ["git", "push", "--mirror"]
              cmd << "--force" if @options.force
              cmd << target_ssh

              if doexec(cmd)
                STDERR.puts "Completed!"
              else
                STDERR.puts "Failed!"
                success = false
              end
            end
          else
            STDERR.puts "Cloning source repository failed!"
            success = false
          end
        end

        success
      end

      def doexec(cmd)
        STDERR.puts(cmd.inspect)
        if !@options.dry_run
          # Execute command
          system(*cmd)
        else
          # Assume command executed correctly
          true
        end
      end
    end
  end
end
