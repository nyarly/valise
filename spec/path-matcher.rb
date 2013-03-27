require 'valise/path-matcher'

describe Valise::PathMatcher, :pending => "Better specification on how PM -> fnmatch works" do
  describe "test/test" do
    let :matcher do
      described_class.build("test/test")
    end

    it "should produce simple fnmatcher" do
      matcher.fnmatchers([]).should == ["test/test"]
    end
  end

  describe "**" do
    let :matcher do
      described_class.build("**")
    end

    it "should produce simple fnmatcher" do
      matcher.fnmatchers([]).should == ["**"]
    end
  end

  describe "with several adjacent paths" do
    let :matcher do
      matcher = described_class.new
      matcher["test/*.rb"] = true
      matcher["test/*.erl"] = true
      matcher["test/*.cpp"] = true
      matcher["test/*.h"] = true
      matcher
    end

    it "should produce alternating fnmatcher" do
      matcher.fnmatchers([]).should == ["test/*.{rb,erl,cpp,h}"]
    end
  end
end
