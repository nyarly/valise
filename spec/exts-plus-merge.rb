require 'valise'
require 'valise/set'
require 'valise/stack'
require 'file-sandbox'

describe Valise, "merging across decorators" do
  include FileSandbox

  let :top_left_hash do #layer2/file.yaml
    {
      "tl" => "tl"
    }
  end

  let :top_right_hash do #layer2/file.yml
    {
      "tl" => "tr",
      "tr" => "tr"
    }
  end

  let :bottom_left_hash do #base/file.yaml
    {
      "tl" => "bl",
      "tr" => "bl",
      "bl" => "bl"
    }
  end

  let :bottom_right_hash do #base/file.yml
    {
      "tl" => "br",
      "tr" => "br",
      "bl" => "br",
      "br" => "br"
    }
  end


  let :valise do
    sandbox.new :directory => "base/test"
    sandbox.new :directory => "layer2/test"
    sandbox["layer2/file.yaml"].contents = YAML::dump(top_left_hash)
    sandbox["layer2/file.yml"].contents = YAML::dump(top_right_hash)
    sandbox["base/file.yaml"].contents = YAML::dump(bottom_left_hash)
    sandbox["base/file.yml"].contents = YAML::dump(bottom_right_hash)

    Valise::Set.define do
      rw "layer2"
      rw "base"

      handle "*.yaml", :yaml, :hash_merge
      handle "*.yml", :yaml, :hash_merge
    end
  end

  let :valise_with_exts do
    valise.exts(".yaml", ".yml")
  end

  it "should order the files correctly" do
    valise_with_exts.get("file").map{|item| item.full_path}.should == %w{ layer2/file.yaml layer2/file.yml base/file.yaml base/file.yml }
  end

  it "should merge everything correctly" do
    valise_with_exts.contents("file").should == {
      "tl" => "tl",
      "tr" => "tr",
      "bl" => "bl",
      "br" => "br"
    }
  end
end
