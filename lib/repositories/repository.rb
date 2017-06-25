require 'repositories/base'

module Repositories
  class Repository
    attr_reader :name, :ref, :branches, :ssh_url, :host

    def initialize(name, ref, ssh_url, host)
      @name = name
      @ref = ref
      @host =  host
      @ssh_url = ssh_url
      @branches = []
    end

    def normalized_name
      name.downcase
    end

    def find_differences(other)
      raise "Not a Repositories::Repository" unless other.is_a? Repositories::Repository

      diffs = []

      branches.each do |branch|
        other_branch = other.branches.find { |otherb| otherb.name == branch.name }

        if other_branch
          if branch.head_commit.sha != other_branch.head_commit.sha
            diffs << {
              type: :different_head_commit,
              ref_branch: branch,
              other_branch: other_branch
            }
          end
        else
          diffs << {
            type: :missing_branch,
            ref_branch: branch
          }
        end
      end

      diffs
    end

    def to_yaml_properties
      [:@name, :@branches, :@ssh_url, :@host]
    end
  end
end
