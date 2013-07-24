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

    @from = Valise::Set.define do
      ro "home/.conductor"

      defaults do
        file :egg, "yolk"
      end
    end

    @to = Valise::Set.define do
      rw ".conductor"
      rw "etc/conductor"
    end
  end

  describe "population" do
    before do
      @from.populate(@to)
    end

    it "should populate successfully" do
      @to.contents("egg").should == "yolk"
      @to.find("existed").contents.should == "TEST"
    end
  end

  describe "reverse population" do
    before do
      @from.populate(@to) do |stack|
        stack.reverse
      end
    end

    it "should populate successfully" do
      @to.find("egg").contents.should == "yolk"
      @to.contents("existed").should == "TEST"
    end
  end
end
