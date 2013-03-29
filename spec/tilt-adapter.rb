require 'tilt'
require 'valise'
require 'file-sandbox'

describe Valise, "tilt adapter" do
  include FileSandbox

  it "should be loaded" do
    defined?(Valise::Strategies::Serialization::Tilt).should be_true
  end

  before :each do
    sandbox.new :directory => "templates"
    sandbox.new :file => "templates/template.erb", :with_contents => "<%= test %>"
  end

  let :template_scope do
    Object.new.tap do |obj|
      def obj.test
        "hello"
      end
    end
  end

  let :valise do
    Valise::read_only(".")
  end

  let :templates do
    valise.templates
  end

  it "should have the Tilt serializer" do
    templates.find("template").stack.dump_load.should be_a(Valise::Strategies::Serialization::Tilt)
  end

  it "should load and render" do
    templates.find("template").contents.render(template_scope, {}).should == "hello"
  end

end
