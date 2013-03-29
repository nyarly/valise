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
    valise.get("not_matched/full").dump_load.should_not be_a(Valise::Strategies::Serialization::YAML)
  end

  it "should not recognize path like a path glob" do
    valise.get("path/full.notpath").should_not be_a(Valise::Strategies::Serialization::YAML)
  end

  it "should recognize based on a full path" do
    valise.get("test/full").dump_load.should be_a(Valise::Strategies::Serialization::YAML)
  end

  it "should recognize base on a file glob" do
    valise.get("test/by.file").dump_load.should be_a(Valise::Strategies::Serialization::YAML)
  end

  it "should recognize simple files based on glob" do
    valise.get("by.file").dump_load.should be_a(Valise::Strategies::Serialization::YAML)
  end

  it "should recognize deep files based on glob" do
    valise.get("a/b/c/d/e/by.file").dump_load.should be_a(Valise::Strategies::Serialization::YAML)
  end

  it "should recognize based on a path glob" do
    valise.get("path/by.path").dump_load.should be_a(Valise::Strategies::Serialization::YAML)
  end
end
