require 'valise'
require 'file-sandbox'

describe Valise, "glob handling" do
  include FileSandbox

  let :valise do
    sandbox.new :directory => "base/test"
    Valise::Set.define do
      handle "test/full", :yaml
      handle "**/*.file", :yaml
      handle "path/*.path", :yaml
      rw "base"
    end
  end

  it "should recognize based on a full path" do
    valise.serialization("test/full").should == Valise::Serialization::YAML
  end

  it "should recognize base on a file glob" do
    valise.serialization("test/by.file").should == Valise::Serialization::YAML
  end

  it "should recognize based on a path glob" do
    valise.serialization("path/by.path").should == Valise::Serialization::YAML
  end
end
