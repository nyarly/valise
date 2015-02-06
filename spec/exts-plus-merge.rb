require 'valise'
require 'valise/set'
require 'valise/stack'
require 'file-sandbox'

describe Valise, :pending => true do
  include FileSandbox

  let :top_left_hash do
    {
      "tl" => "bl"
    }
  end

  let :top_right_hash do
    {
      "tl" => "tr",
      "tr" => "tr"
    }
  end

  let :bottom_left_hash do
    {
      "tl" => "bl",
      "tr" => "bl",
      "bl" => "bl"
    }
  end

  let :bottom_right_hash do
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
    sandbox["base/file.yaml"].contents = YAML::dump(bottom_left_hash)
    sandbox["base/file.yml"].contents = YAML::dump(bottom_right_hash)
    sandbox["layer2/file.yaml"].contents = YAML::dump(top_left_hash)
    sandbox["layer2/file.yml"].contents = YAML::dump(top_left_hash)

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

  it "should merge everything correctly" do
    valise_with_exts.contents("file").should == {
      "tl" => "tl",
      "tr" => "tr",
      "bl" => "bl",
      "br" => "br"
    }
  end
end
