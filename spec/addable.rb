require 'valise'
require 'file-sandbox'

describe Valise do
  include FileSandbox

  before do
    sandbox.new :directory => "etc/conductor"
    sandbox.new :directory => "home/.conductor"
    sandbox.new :directory => ".conductor"
    sandbox.new :directory => "spec"
    sandbox.new :file => "home/.conductor/existed", :with_contents => "TEST"
    one = Valise::Set.define do
      handle "test", :yaml
      rw ".conductor"
    end

    two = Valise::Set.define do
      handle "test", nil, :hash_merge
      defaults do
      end
    end

    @sum = one + two
  end


  it "should be addable" do
    @sum.should be_an_instance_of(Valise::Set)
  end

  it "should add in order" do
    @sum[0].should be_an_instance_of(Valise::SearchRoot)
    @sum[1].should be_an_instance_of(Valise::DefinedDefaults)
  end

  it "should combine file handlers" do
    @sum.merge_diff_for("test").should == Valise::MergeDiff::HashMerge
    @sum.serialization_for("test").should == Valise::Serialization::YAML
  end
end
