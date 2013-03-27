require 'valise'
require 'file-sandbox'

describe Valise do
  include FileSandbox

  let :bottom_hash do
    {}
  end

  let :middle_hash do
    {}
  end

  let :top_hash do
    {}
  end


  let :valise do
    sandbox.new :directory => "base/test"
    sandbox.new :directory => "layer2/test"
    sandbox.new :directory => "layer3/test"
    sandbox["base/test/file"].contents = YAML::dump(bottom_hash)
    sandbox["layer2/test/file"].contents = YAML::dump(middle_hash)
    sandbox["layer3/test/file"].contents = YAML::dump(top_hash)

    Valise::Set.define do
      handle "test/file", :yaml, :hash_merge
      rw "layer3"
      rw "layer2"
      rw "missing"
      rw "base"
    end
  end

  let :item do
    valise.get("test/file").first
  end

  describe "merge" do
    it "should merge values from the bottom" do
      bottom_hash[:a] = 3
      item.contents.should == {:a => 3}
    end

    it "should obscure values from lower down" do
      bottom_hash[:a] = 3
      middle_hash[:a] = 1
      item.contents.should == {:a => 1}
    end

    it "should prefer topmost value" do
      bottom_hash[:a] = 3
      middle_hash[:a] = 2
      top_hash[:a] = 1

      item.contents.should == {:a => 1}
      item.stack.map{|stack| stack.contents[:a]}.should == [1,2,3,3]
    end

    it "should prefer top nil to bottom value" do
      bottom_hash[:a] = 3
      top_hash[:a] = nil
      item.contents[:a].should == nil
    end

    it "should do a deep merge" do
      bottom_hash[:a] = {:a => {:a => 3}}
      middle_hash[:a] = {:a => {:a => 2}}
      top_hash[:a] = {:a => {:a => 1}}

      item.stack.map{|stack| stack.contents[:a][:a][:a]}.should == [1,2,3,3]
    end
  end

  describe "diff" do
    before :each do
      bottom_hash.merge!(:a => 1, :b => 2, :c => "bad")
      top_hash.merge!(:a => 2, :b => 7)
      item.contents = {:a => 1, :b => 3}
    end

    it "should reduce actual contents of an item to minimal" do
      item.contents[:a].should == 1
      item.load_contents[:a].should be_nil
    end

    it "should mask missing keys" do
      item.contents[:c].should be_nil
    end
  end
end
