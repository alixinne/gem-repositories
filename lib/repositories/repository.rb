require 'repositories/base'

module Repositories
  class Repository
    attr_reader :name, :ref, :ssh_url, :host

    def self.to_rep_name(name)
      name.downcase.tr(' .-/', '-').gsub(/-+/, '-')
    end

    def initialize(name, ref, ssh_url, host)
      @name = Repository.to_rep_name(name)
      @ref = ref
      @host =  host
      @ssh_url = ssh_url

      @branches = nil
      @branches_source = Enumerator.new do |yielder|
        yield(self, yielder)
      end
    end

    def branches
      if @branches.nil?
        @branches = @branches_source.to_a
        @branches_source = nil
      end

      @branches
    end

    def normalized_name
      name.downcase
    end

    def most_recent_head
      branches.max_by { |branch| branch.head_commit.date }.head_commit
    end

    def find_differences(other)
      raise "Not a Repositories::Repository" unless other.is_a? Repository

      diffs = []
      branches.each do |branch|
        other_branch = other.branches.find do |otherb|
          otherb.name == branch.name
        end

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

    def on_push
      host.on_push(self) do
        yield
      end
    end

    def to_yaml_properties
      %i[@name @branches @ssh_url @host]
    end
  end
end
