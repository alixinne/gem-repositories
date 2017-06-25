require "spec_helper"

RSpec.describe Repositories do
  it "has a version number" do
    expect(Repositories::VERSION).not_to be nil
  end
end
