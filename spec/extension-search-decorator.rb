require 'valise/set'
require 'valise/stack'

describe Valise::ExtensionsSearchDecorator do
  let :valise do
    Valise::Set::define do
      rw "top"
      rw "middle"
      rw "bottom"
    end
  end

  let :base_stack do
    valise.get("thing")
  end

  let :first_exts do
    base_stack.exts("", ".a", ".b", ".c")
  end

  let :second_exts do
    Valise::ExtensionsSearchDecorator.new(first_exts).tap do |exts|
      exts.extensions = ["", ".x", ".y", ".z"]
    end
  end

  it "should enumerate paths correctly" do
    second_exts.map{|item| item.full_path}.should == %w{
      top/thing     top/thing.x   top/thing.y   top/thing.z
      top/thing.a   top/thing.a.x top/thing.a.y top/thing.a.z
      top/thing.b   top/thing.b.x top/thing.b.y top/thing.b.z
      top/thing.c   top/thing.c.x top/thing.c.y top/thing.c.z

      middle/thing     middle/thing.x   middle/thing.y   middle/thing.z
      middle/thing.a   middle/thing.a.x middle/thing.a.y middle/thing.a.z
      middle/thing.b   middle/thing.b.x middle/thing.b.y middle/thing.b.z
      middle/thing.c   middle/thing.c.x middle/thing.c.y middle/thing.c.z

      bottom/thing     bottom/thing.x   bottom/thing.y   bottom/thing.z
      bottom/thing.a   bottom/thing.a.x bottom/thing.a.y bottom/thing.a.z
      bottom/thing.b   bottom/thing.b.x bottom/thing.b.y bottom/thing.b.z
      bottom/thing.c   bottom/thing.c.x bottom/thing.c.y bottom/thing.c.z
    }
  end
end
