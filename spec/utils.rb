require 'valise/utils'
require 'file-sandbox'
require 'fileutils'

describe Valise::Unpath do
  let :module_host do
    Object.new.tap do |obj|
      obj.extend Valise::Unpath

      obj.instance_eval do
        class << self
          public :make_pathname
        end
      end
    end
  end

  describe "#make_pathname" do
    it '["", "etc", "configs"] => /etc/configs' do
      module_host.make_pathname(["", "etc", "configs"]).should == Pathname.new("/etc/configs")
    end
  end

  describe "#current_directory" do
    include FileSandbox

    before do
      sandbox.new :directory => "some/levels/deep"
      FileUtils.symlink("some/levels/deep", "shallow")
      Dir.chdir("shallow")
    end

    subject :path do
      Valise::Unpath.current_directory
    end

    it "should real working directory" do
      path.to_s.should =~ /deep$/
    end

    it "should return a Pathname" do
      path.should be_an_instance_of(Pathname)
    end
  end

  describe "#starting_directory" do
    it "should return a Pathname" do
      Valise::Unpath.start_dir.should be_an_instance_of(Pathname)
    end
  end

  describe Valise::Unpath::WorkspaceFinder do
    include FileSandbox
    before do
      sandbox.new :directory => "weird"
      sandbox.new :directory => "down/the/rabbit/hole"
      Dir.chdir "down/the/rabbit/hole"
    end

    subject :finder do
      Valise::Unpath::WorkspaceFinder.new.tap do |finder|
        finder.search_from = "."
        finder.workspace_children = ["weird"]
        finder.description = "Weird test workspace"
      end
    end

    it "should find workspace" do
      finder.find.to_s.should == @sandbox.root
    end

    it "should return a pathname" do
      finder.find.should be_an_instance_of Pathname
    end
  end

  describe "#up_to" do
    it "should walk up paths" do
      Valise::Unpath.up_to("spec").to_s.should =~ /.*spec$/
    end

    it "should find a lib" do
      module_host.up_to("lib", "/a/b/c/lib/d/e/f").to_s.should == "/a/b/c/lib"
    end

    it "should raise if not available" do
      expect do
        module_host.up_to("surely/notpathsegment") #because / is the separator
      end.to raise_error(/not found/)
    end
  end

  describe "#from_here" do
    it "should manage relative paths" do
      module_host.from_here("../../thing", "/a/b/c/d/e").to_s.should == "/a/b/c/thing"
    end
  end

  describe "#file_from_backtrace" do
    it "should get filename properly" do
      module_host.file_from_backtrace(caller(0)[0]).should == __FILE__
    end
  end
end
