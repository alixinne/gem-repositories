require "spec_helper"

RSpec.describe Repositories do
  it "has a version number" do
    expect(Repositories::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
