require 'valise/utils'
describe Valise::Unpath do
  let :module_host do
    Object.new.tap do |obj|
      obj.extend Valise::Unpath

      obj.instance_eval do
        class << self
          public :unpath
        end
      end
    end
  end

  describe "#up_to" do
    it "should walk up paths" do
      Valise::Unpath.up_to("spec").should =~ /.*spec$/
    end
  end

  describe "#unpath" do
    it 'state => ["state"]' do
      module_host.unpath("state").should == %w{state}
    end

    it '["step", "step/step"] => ["step", "step", "step"]' do
      module_host.unpath(["step", "step/step"]).should == %w{step step step}
    end

    it '/etc/configs => ["", "etc", "configs"]' do
      module_host.unpath("/etc/configs").should == [""] + %w{etc configs}
    end

    it '["", "etc", "configs"] => ["", "etc", "configs"]' do
      module_host.unpath(["", "etc", "configs"]).should == [""] + %w{etc configs}
    end

    it 'a File => #path' do
      @file = File.new(__FILE__)
      @path = __FILE__.split("/")
      module_host.unpath(@file)
    end
  end

  describe "#up_to" do
    it "should find a lib" do
      module_host.up_to("lib", "/a/b/c/lib/d/e/f").should == "/a/b/c/lib"
    end

    it "should raise if not available" do
      expect do
        module_host.up_to("surely/notpathsegment") #because / is the separator
      end.to raise_error(/not found/)
    end
  end

  describe "#from_here" do
    it "should manage relative paths" do
      module_host.from_here("../../thing", "/a/b/c/d/e").should == "/a/b/c/thing"
    end
  end

  describe "#file_from_backtrace" do
    it "should get filename properly" do
      module_host.file_from_backtrace(caller(0)[0]).should == __FILE__
    end
  end
end
