require 'tilt'
require 'valise'
require 'file-sandbox'

describe Valise, "tilt adapter" do
  include FileSandbox

  let :valise do
    Valise::read_only(".")
  end

  let :templates do
    valise.templates
  end

  describe "for ERB" do

    it "should be loaded" do
      defined?(Valise::Strategies::Serialization::Tilt).should be_true
    end

    before :each do
      sandbox.new :directory => "templates"
      sandbox.new :file => "templates/template.erb", :with_contents => "<%= render 'included' %>"
      sandbox.new :file => "templates/included.erb", :with_contents => "<%= test %>"
      sandbox.new :file => "templates/plain-file",   :with_contents => "<%= test %>"
    end

    let :template_scope do
      Object.new.tap do |obj|
        def obj.render(path)
          @templates.contents(path).render(self, {})
        end

        def obj.test
          "hello"
        end

        obj.instance_variable_set("@templates", templates)
      end
    end

    it "should have the Tilt serializer" do
      templates.find("template").stack.dump_load.should be_a(Valise::Strategies::Serialization::Tilt)
    end

    it "should load and render" do
      template_scope.render("template").should == "hello"
    end

    it "should load templates" do
      contents = templates.contents("template")
      contents.should be_a_kind_of(Tilt::Template)
    end

    it "should load plain files" do
      contents = templates.contents("plain-file")
      contents.should_not be_a_kind_of(Tilt::Template)
      contents.should == "<%= test %>"
    end
  end
end
