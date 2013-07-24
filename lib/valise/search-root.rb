require 'valise/errors'
require 'valise/utils'
require 'valise/item'
require 'fileutils'
#require 'enum'

module Valise
  class SearchRoot
    include Unpath
    include Enumerable

    def initialize(path)
      @segments = make_pathname(path)
    end

    attr_accessor :segments

    def each(pathmatch = nil)
      paths = [make_pathname("")]
      until paths.empty?
        rel = paths.shift
        path = @segments + rel
        #symlinks?
        if path.directory?
          paths += path.children(false).map do |child|
            rel + child
          end
        elsif path.file?
          yield rel
        end
      end
    end

    def inspect
      "#{self.class.name.split(":").last}:#{[*@segments].join("/")}"
    end

    def to_s
      "#{[*@segments].join("/")}"
    end

    def full_path(segments)
      (@segments + make_pathname(segments)).to_s
    end

    def write(item)
      return if item.contents.nil?
      FileUtils::mkdir_p(::File::dirname(item.full_path))
      File::open(item.full_path, "w") do |file|
        file.write(item.dump_contents)
      end
      item
    end

    def writable?(segments)
      path = full_path(segments)
      return (!File::exists?(path) or File::writable?(path))
    end

    def present?(segments)
      return File::exists?(full_path(segments))
    end

    def get_from(item)
      File::read(item.full_path)
    end
  end

  class ReadOnlySearchRoot < SearchRoot
    def writable?(segments)
      false
    end

    def write(item)
      raise Errors::ReadOnly
    end
  end

  class DefinedDefaults < ReadOnlySearchRoot
    def initialize
      @files = {}
    end

    def segments
      raise Errors::VirtualSearchPath, "does not have a real path"
    end

    def full_path(segments)
      "<DEFAULTS>:" + segments.to_s
    end

    def present?(segments)
      @files.has_key?(segments)
    end

    def each
      @files.each_key do |path|
        yield(make_pathname(path))
      end
    end

    def get_from(item)
      return @files[item.segments]
    end

    def define(&block)
      unless block.nil?
        definer = DefinitionHelper.new(self)
        definer.instance_eval &block
      end
      return self
    end

    def self.define(&block)
      return self.new.define(&block)
    end

    def add_item(path, contents)
      check_path = path[0..-2]
      until check_path.empty?
        if @files.has_key?(check_path)
          raise Errors::MalformedTree, "Tried to add items below #{path[0..-2]} which is not a directory"
        end
        check_path.pop
      end
      @files[make_pathname(path)] = contents
    end

    def add_dir(path)
      #add_item(path, ValiseWorks::Directory.new(path))
    end

    def add_file(path, data = nil)
      add_item(path, data)
    end

    class DefinitionHelper
      def initialize(target)
        @target = target
        @prefix = []
      end

      def dir(name)
        path = @prefix + [name]
        @target.add_dir(path)
        @prefix.push(name)
        yield if block_given?
        @prefix.pop
      end

      def file(name, data=nil)
        path = @prefix + [name.to_s]
        @target.add_file(path, data)
      end

      include StringTools
    end
  end
end
