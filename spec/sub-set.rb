require 'valise'
require 'file-sandbox'

describe Valise::SubSet do
  include FileSandbox

  before :each do
    sandbox.new :directory => "sub"
    sandbox.new :file => "at_root", :with_contents => "/"
    sandbox.new :file => "sub/test", :with_contents => "TEST"
  end

  let :valise do
    Valise.define do
      rw "."
    end
  end

  let :child_set do
    valise.sub_set("sub")
  end

  it "should find files as if a new Set" do
    child_set.find("test").contents.should == "TEST"
  end

  it "should not find files above the sub path" do
    valise.find("at_root").contents.should == "/"
    expect do
      child_set.find("at_root")
    end.to raise_error(Valise::Errors::NotFound)
  end


  it "should manipulate the same files as the parent" do
    child_set.find("test").contents = "CHANGED"
    valise.find("sub/test").contents.should == "CHANGED"
  end
end
