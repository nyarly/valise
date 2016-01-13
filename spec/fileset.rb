require 'valise'
require 'file-sandbox'

describe Valise, "error cases" do
end

describe Valise do
  include FileSandbox

  before do
    sandbox.new :directory => "etc/conductor"
    sandbox.new :directory => "home/.conductor"
    sandbox.new :directory => ".conductor"
    sandbox.new :directory => "spec"
    sandbox.new :file => "home/.conductor/existed", :with_contents => "TEST"
    @valise = Valise::Set.define do
      rw ".conductor"
      rw "home/.conductor"
      rw "etc/conductor"
      defaults do
        file :text, align(<<-EOT)
        <<<
        Some text
        EOT

        dir "nest" do
          file "egg", "yolk"
        end
      end
    end
  end

  it "should be a Valise::Set" do
    @valise.should be_an_instance_of(Valise::Set)
  end

  describe "retrieving files" do
    it "should get default text files" do
      @valise.contents("text").should == "Some text"
      @valise.find(:text).contents.should == "Some text"
    end

    it "should get text files from library files" do
      @valise.find("existed").contents.should == "TEST"
    end

    it "should get default nested files" do
      @valise.find(%w{nest egg}).contents.should == "yolk"
    end

    it "should get text files from filesystem" do
      sandbox.new :file => "home/.conductor/text", :with_contents => "Other text"
      @valise.find(:text).contents.should == "Other text"
      @valise.find("text").contents.should == "Other text"
    end
  end

  shared_examples_for "a populating Valise" do
    it "should create files on populate" do
      pending

      @valise.populate

      sandbox["etc/conductor/tool_configs"].should exist
      sandbox["home/.conductor/tool_configs"].should exist
      sandbox[".conductor/tool_configs"].should exist
      sandbox[".conductor/tool_configs/test"].should exist
      sandbox[".conductor/tool_configs/test"].contents.should == "TEST"
      sandbox["etc/conductor/tool_configs/test"].should_not exist
      sandbox["home/.conductor/tool_configs/test"].should_not exist
    end

    it "should not clobber existing files in populate" do
      pending
      sandbox.new :file => ".conductor/tool_configs/test", :with_contents => "not test"

      @valise.populate

      sandbox["etc/conductor/tool_configs"].should exist
      sandbox["home/.conductor/tool_configs"].should exist
      sandbox[".conductor/tool_configs"].should exist
      sandbox[".conductor/tool_configs/test"].should exist
      sandbox[".conductor/tool_configs/test"].contents.should == "not test"
      sandbox["etc/conductor/tool_configs/test"].should_not exist
      sandbox["home/.conductor/tool_configs/test"].should_not exist

    end

    it "should allow empty directory definition" do
      pending
      @valise.populate

      sandbox["etc/conductor/empty"].should exist
      sandbox[".conductor/empty"].should exist
      sandbox["home/.conductor/empty"].should exist
    end

    it "should get files once populated" do
      pending
      @valise.populate

      file = @valise.get_file(%w{tool_configs test})

      file.contents.should == "TEST"
      file.contents = "not test"
      file.store

      file2 = @valise.get_file(%w{tool_configs test})
      file2.contents.should == "not test"
    end
  end

  if false
    describe "defined with the DSL" do
      #it_should_behave_like "a populating Valise"

      before do
        @valise.define do
          dir "tool_configs" do
            file "test", "TEST"
          end
          dir "empty"
        end
      end
    end

    describe "defined programmatically" do
      it_should_behave_like "a populating Valise"

      before do
        @valise.add_file(%w{tool_configs test}, "TEST")
        @valise.add_dir(%w{empty})
      end
    end
  end
end
