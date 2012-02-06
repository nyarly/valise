require 'valise'
require 'file-sandbox'

describe Valise do
  include FileSandbox

  let :valise do
    sandbox.new :directory => "base/test"
    Valise::Set.define do
      handle "test/yaml-file", :yaml
      rw "base"
    end
  end

  let :item do
    valise.get("test/yaml-file").first
  end

  it "should store data as YAML" do
    item.contents = { :a => "test hash" }
    item.save
    YAML::load( File::read(item.full_path)).should == { :a => "test hash" }
  end

  it "should load data from YAML" do
    File::open(item.full_path, "w") do |file|
      file.write(YAML::dump( :another => "test hash" ))
    end
    item.contents.should == {:another => "test hash"}
  end
end
