require 'valise'
require 'file-sandbox'

describe Valise, "with stemming" do
  include FileSandbox

  before do
    sandbox.new :directory => "conductor"
    sandbox.new :directory => "other_dir"
    sandbox.new :file => "conductor/top", :with_contents => "conductor/exists"
    sandbox.new :file => "other_dir/middle", :with_contents => "other_dir/exists"

    @valise = Valise::Set.define do
      stemmed("stem").rw("conductor")
      stemmed("stem") do
        rw "other_dir"
      end
      rw "conductor"
    end
  end

  it "should find a file in a stemed dir" do
    @valise.find("stem/top").contents.should == "conductor/exists"
  end

  it "should find a file in a stemed dir defined in a block" do
    @valise.find("stem/middle").contents.should == "other_dir/exists"
  end

  it "should find a file in a normal dir behind stemming" do
    @valise.find("top").contents.should == "conductor/exists"
  end
end
