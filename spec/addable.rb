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
  end

  let :one do
    Valise::Set.define do
      handle "test", :yaml
      rw ".conductor"
    end
  end

  let :two do
    Valise::Set.define do
      handle "test", nil, :hash_merge
      defaults do
      end
    end
  end

  let :sum do
    one + two
  end

  it "should be addable" do
    sum.should be_an_instance_of(Valise::Set)
  end

  it "should add in order" do
    sum[0].should be_an_instance_of(Valise::SearchRoot)
    sum[1].should be_an_instance_of(Valise::DefinedDefaults)
  end

  it "should combine file handlers" do
    sum.get("test").merge_diff.should be_a(Valise::Strategies::MergeDiff::HashMerge)
    sum.get("test").dump_load.should be_a(Valise::Strategies::Serialization::YAML)
  end
end
