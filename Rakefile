require 'corundum'
require 'corundum/tasklibs'

module Corundum
  tk = Toolkit.new do |tk|
    tk.file_lists.project += ['.rspec', '.simplecov']
  end

  tk.in_namespace do
    sanity = GemspecFiles.new(tk)
    rspec = RSpec.new(tk)
    cov = SimpleCov.new(tk, rspec) do |cov|
      cov.threshold = 90
    end
    gem = GemBuilding.new(tk)
    cutter = GemCutter.new(tk,gem)
    vc = Git.new(tk) do |git|
      git.branch = "master"
    end
  end
end

Dir['gemfiles/*'].delete_if{|path| path =~ /lock\z/ }.each do |gemfile|
  gemfile_lock = gemfile + ".lock"
  file gemfile_lock => [gemfile, "valise.gemspec"] do
    Bundler.with_clean_env do
      sh "bundle install --gemfile #{gemfile}"
    end
  end

  desc "Update all the bundler lockfiles for Travis"
  task :travis_gemfiles => gemfile_lock
end
