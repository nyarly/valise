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

  it "should not recognize unmatched path" do
    valise.serialization_for("not_matched/full").should_not == Valise::Serialization::YAML
  end

  it "should not recognize path like a path glob" do
    valise.serialization_for("path/full.notpath").should_not == Valise::Serialization::YAML
  end

  it "should recognize based on a full path" do
    valise.serialization_for("test/full").should == Valise::Serialization::YAML
  end

  it "should recognize base on a file glob" do
    valise.serialization_for("test/by.file").should == Valise::Serialization::YAML
  end

  it "should recognize based on a path glob" do
    valise.serialization_for("path/by.path").should == Valise::Serialization::YAML
  end
end
