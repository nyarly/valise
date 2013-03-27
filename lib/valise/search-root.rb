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
      @segments = unpath(path)
    end

    attr_accessor :segments

    #ALL_FILES = PathMatcher.build('**')
    def each(pathmatch = nil)
#      pathmatch ||= ALL_FILES
#      files = pathmatch.fnmatchers(@segments).inject([]) do |list, fnmatch|
#        list + Dir.glob(fnmatch).find_all{|path| File::file?(path)}
#      end
#      pathmatch.sort(files).each
#
#
      paths = [[]]
      until paths.empty?
        rel = paths.shift
        path = repath(@segments + rel)
        #symlinks?
        if(File::directory?(path))
          Dir.entries(path).each do |entry|
            next if entry == "."
            next if entry == ".."
            paths.push(rel + [entry])
          end
        elsif(File::file?(path))
          yield(unpath(rel))
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
      repath(@segments + segments)
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

    def insert(item)
      if(File::exists?(item.full_path))
        raise Errors::WouldClobber.new(Item.new(item.stack.segments, self, nil))
      else
        write(item)
        return item
      end
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

    def insert(item)
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

    def present?(segments)
      @files.has_key?(segments)
    end

    def each
      @files.each_key do |path|
        yield(unpath(path))
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
      @files[path] = contents
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
