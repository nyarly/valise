require 'valise/path-matcher'

describe Valise::PathMatcher do
  subject :matcher do
    Valise::PathMatcher.new
  end

  it "should translate flag symbols" do
    matcher.set("dontcare", true, %i[extended nocase pathname])
    matcher.set("alsodull", false, %i[noescape dotmatch])

    first, second = *matcher.to_a

    expect(first.flags).to eq(File::FNM_EXTGLOB | File::FNM_CASEFOLD | File::FNM_PATHNAME)
    expect(second.flags).to eq(File::FNM_NOESCAPE | File::FNM_DOTMATCH)
  end
end
