Gem::Specification.new do |spec|
  spec.name		= "valise"
  #{MAJOR: incompatible}.{MINOR added feature}.{PATCH bugfix}-{LABEL}
  spec.version		= "1.0.0"
  author_list = {
    "Judson Lester" => "nyarly@gmail.com"
  }
  spec.authors		= author_list.keys
  spec.email		= spec.authors.map {|name| author_list[name]}
  spec.summary		= "Manage configuration and data files simply"
  spec.description	= <<-EOD
  Valise provides an API for accessing configuration and data files for your
  application, including the population of default values, and managing search
  paths.  Written to encourage a cross-platform approach to maintaining configs
  for an application.
  EOD

  spec.rubyforge_project= spec.name.downcase
  spec.homepage        = "http://#{spec.rubyforge_project}.rubyforge.org/"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  # Do this: y$@"
  # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f 2>/dev/null
  spec.files		= %w[
    doc/README
    doc/Specification
    doc/Specifications

    lib/valise.rb
    lib/valise/item-enum.rb
    lib/valise/utils.rb
    lib/valise/errors.rb
    lib/valise/adapters.rb

    lib/valise/strategies/set.rb
    lib/valise/strategies/merge-diff.rb
    lib/valise/strategies/serialization.rb

    lib/valise/adapters/tilt.rb

    lib/valise/path-matcher.rb
    lib/valise/search-root.rb

    lib/valise/set.rb
    lib/valise/set/definer.rb
    lib/valise/set/extensions-decorator.rb

    lib/valise/stack.rb
    lib/valise/stack/extensions-decorator.rb
    lib/valise/stem-decorator.rb

    lib/valise/item.rb

    spec/addable.rb
    spec/dump-load.rb
    spec/error-handling.rb
    spec/fileset.rb
    spec/glob-handling.rb
    spec/item.rb
    spec/merge-diff.rb
    spec/population.rb
    spec/search-root.rb
    spec/stemming.rb
    spec_help/file-sandbox.rb
    spec_help/gem_test_suite.rb
    spec_help/spec_helper.rb
    spec_help/ungemmer.rb
  ]

  spec.test_file        = "spec_help/gem_test_suite.rb"
  spec.licenses = ["MIT"]
  spec.require_paths = %w[lib/]
  spec.rubygems_version = "1.3.5"

  if spec.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    spec.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      spec.add_development_dependency "corundum"
    else
      spec.add_development_dependency "corundum"
    end
  else
    spec.add_development_dependency "corundum"
  end

  #spec.add_dependency "diff-lcs", ">= 1.1"

  spec.has_rdoc		= true
  spec.extra_rdoc_files = Dir.glob("doc/**/*")
  spec.rdoc_options	= %w{--inline-source }
  spec.rdoc_options	+= %w{--main doc/README }
  spec.rdoc_options	+= ["--title", "#{spec.name}-#{spec.version} RDoc"]

  #spec.post_install_message = "Another tidy package brought to you by Judson"
end
