require 'fileset'
require 'file-sandbox'

describe FileSet, "error cases" do
  describe "population to non-permitted directories" do
    before :each do
      @fileset = FileSet.new(["", "no_such_dir"])
      @fileset.define do
        file :blag, "Nothing special"
      end
    end

    it "should quitely fail" do
      FileSetWorks::Population::debug
      proc do
        @fileset.populate
      end.should_not raise_error
    end

    after do
      FileSetWorks::Population::EveryPath.class_eval do
        def remark(string); end
      end
    end

  end
end

describe FileSet do
  include FileSandbox

  before do
    sandbox.new :directory => "etc/conductor"
    sandbox.new :directory => "home/.conductor"
    sandbox.new :directory => ".conductor"
    sandbox.new :directory => "spec"
    sandbox.new :file => "spec/source.txt", :with_contents => "TEST"
    @fileset = FileSet.new([%w{etc conductor}, %w{home .conductor}, %w{.conductor}])
  end

  describe "retrieving files" do
    before do
      @fileset.define do
        file :text, align(<<-EOT)
        <<<
        Some text
        EOT

        file :from_file, contents_from(%w{source.txt})

        yaml_file :yaml do
          {:one => 1}
        end

        yaml_file "other" do
          [3,4,5]
        end

        dir "nest" do
          file "egg", "yolk"
        end
      end
    end

    it "should get default text files" do
      @fileset.load("text").should == "Some text"
      @fileset.load(:text).should == "Some text"
    end

    it "should get text files from library files" do
      @fileset.load("from_file").should == "TEST"
    end

    it "should get default nested files" do
      @fileset.load(%w{nest egg}).should == "yolk"
    end

    it "should get text files from filesystem" do
      sandbox.new :file => "home/.conductor/text", :with_contents => "Other text"
      @fileset.load(:text).should == "Other text"
      @fileset.load("text").should == "Other text"
    end

    it "should get yaml files named with strings" do
      @fileset.load(:yaml).should == {:one => 1}
      @fileset.load("yaml").should == {:one => 1}
    end

    it "should get yaml files from the filesystem" do
      sandbox.new :file => "home/.conductor/yaml", :with_contents => "--- \n- Coo\n"
      @fileset.load(:yaml).should == ["Coo"]
      @fileset.load("yaml").should == ["Coo"]
    end

    it "should get yaml files named with symbols" do
      @fileset.load(:other).should == [3,4,5]
      @fileset.load("other").should == [3,4,5]
    end
  end

  share_examples_for "a populating FileSet" do
    it "should create files on populate" do

      @fileset.populate

      sandbox["etc/conductor/tool_configs"].should exist
      sandbox["home/.conductor/tool_configs"].should exist
      sandbox[".conductor/tool_configs"].should exist
      sandbox[".conductor/tool_configs/test"].should exist
      sandbox[".conductor/tool_configs/test"].contents.should == "TEST"
      sandbox["etc/conductor/tool_configs/test"].should_not exist
      sandbox["home/.conductor/tool_configs/test"].should_not exist
    end

    it "should not clobber existing files in populate" do
      sandbox.new :file => ".conductor/tool_configs/test", :with_contents => "not test"

      @fileset.populate

      sandbox["etc/conductor/tool_configs"].should exist
      sandbox["home/.conductor/tool_configs"].should exist
      sandbox[".conductor/tool_configs"].should exist
      sandbox[".conductor/tool_configs/test"].should exist
      sandbox[".conductor/tool_configs/test"].contents.should == "not test"
      sandbox["etc/conductor/tool_configs/test"].should_not exist
      sandbox["home/.conductor/tool_configs/test"].should_not exist

    end

    it "should allow empty directory definition" do
      @fileset.populate

      sandbox["etc/conductor/empty"].should exist
      sandbox[".conductor/empty"].should exist
      sandbox["home/.conductor/empty"].should exist
    end

    it "should get files once populated" do
      @fileset.populate

      file = @fileset.get_file(%w{tool_configs test})

      file.contents.should == "TEST"
      file.contents = "not test"
      file.store

      file2 = @fileset.get_file(%w{tool_configs test})
      file2.contents.should == "not test"
    end
  end

  describe "defined with the DSL" do
    it_should_behave_like "a populating FileSet"

    before do
      @fileset.define do
        dir "tool_configs" do
          file "test", "TEST"
        end
        dir "empty"
      end
    end
  end

  describe "defined programmatically" do
    it_should_behave_like "a populating FileSet"

    before do
      @fileset.add_file(%w{tool_configs test}, "TEST")
      @fileset.add_dir(%w{empty})
    end
  end
end

describe FileSet, " - the unpath method: " do
  before do
    @fileset = FileSet.new("")
  end

  it 'state => ["state"]' do
    @fileset.unpath("state").should == %w{state}
  end

  it 'a File => #path' do
    @file = File.new(__FILE__)
    @path = __FILE__.split("/")
    @fileset.unpath(@file)
  end
end
