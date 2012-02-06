require 'valise'
require 'file-sandbox'

describe "Invidual items in the set" do
  include FileSandbox
  let (:root_path) do
    sandbox.new :directory => "root"
    sandbox.new :file => "root/item", :with_contents => "testing"
    "root"
  end
  let (:set) do
    path = root_path
    Valise::Set.define do
      rw path
    end
  end

  subject { set.find("item") }

  its (:full_path) { should == "root/item" }

  describe "#contents=" do
    its (:contents) { should == "testing" }

    it "raw_file" do
      subject.raw_file.path.should == "root/item"
    end

    it "should make contents available" do
      subject.open do |file|
        file.read.should == "testing"
      end
    end
  end
end
