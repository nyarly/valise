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

  it { expect(subject.full_path).to eq "root/item" }

  describe "#contents=" do
    it { expect(subject.contents).to eq "testing" }

    it "raw_file" do
      expect(subject.raw_file.path).to eq "root/item"
    end

    it "should make contents available" do
      subject.open do |file|
        expect(file.read).to eq "testing"
      end
    end
  end
end
