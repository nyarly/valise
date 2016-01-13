require 'spec_helper'
require 'file-sandbox'
require 'valise/search-root'

describe Valise::SearchRoot do
  include FileSandbox

  before do
    sandbox.new :directory => "test"
    sandbox.new :file => "test/file", :with_contents => "TEST"
  end

  let :search_root do
    Valise::SearchRoot.new("test")
  end

  it "should find a file in the root" do
    expect(search_root.present?(%w{file})).to eq true
  end

  it "should raise PathNotInRoot if path isn't in root" do
    expect(search_root.present?(%w{nothere})).to eq false
  end
end
