require 'yaml'
require 'fileutils'

module ValiseWorks
  module Population
    class EveryPath
      def initialize(file_rep, search_paths)
        @rep = file_rep
        @search_paths = search_paths
      end

      def remark(msg); end

      def populate
        catch :done do
          paths do |sp|
            begin
              remark("Populating #{sp.inspect}...")
              per_path(sp)
              remark("Success")
            rescue SystemCallError
              remark("Failed")
              next
            end
          end
        end
      end

      def paths
        @search_paths.each do |sp|
          yield sp
        end
      end

      def per_path(search_path)
        @rep.create_in(search_path)
      end
    end

    def self.debug
      EveryPath.class_eval do
        def remark(string)
          puts string
        end
      end
    end

    class LowestPath < EveryPath
      def per_path(search_path)
        @rep.create_in(search_path)
        throw :done
      end

      def paths
        @search_paths.reverse.each do |sp|
          yield sp
        end
      end
    end

    class HighestPath < EveryPath
      def per_path(search_path)
        @rep.create_in(search_path)
        throw :done
      end
    end
  end
end

class Valise
  def initialize(search_paths)
    @prefix = []
    @files = {}
    @search_paths = search_paths.map{|p| unpath([*p])}
  end

  def find(path)
    path = unpath(path)
    @search_paths.reverse.map do |sp|
      ::File::join(sp + path)
    end.find do |path|
      ::File::exists?(path)
    end
  end

  def load(*path)
    get_file(path).contents
  end

  def get_file(path)
    path = unpath(path)
    file_rep = @files[path]
    unless (file_path = find(path)).nil?
      file = ValiseWorks::LiveFile.new(file_path, file_rep)
      file.load
      return file
    end
    return file_rep
  end

  def populate()
    @files.keys.sort do |left, right|
      left.length <=> right.length
    end.each do |key|
      @files[key].populate(@search_paths)
    end
  end

  def unpath(parts)
    if Array === parts and parts.length == 1
      parts = parts[0]
    end

    case parts
    when Array
      if (parts.find{|part| not (String === part or Symbol === part)}.nil?)
        parts = parts.map{|part| part.to_s}
      else
        raise "path must be composed of strings or symbols"
      end
    when String
      parts = path_split(parts)
    when Symbol
      parts = [parts.to_s]
    when ::File
      parts = parts.path
      parts = path_split(parts)
    else
      raise "path must be String, Array of Strings or File"
    end

    parts = parts.map do |part|
      if /^~/ =~ part
        ::File::expand_path(part).split(::File::Separator)
      else
        part
      end
    end.flatten

    return parts
  end

  def define(&block)
    self.instance_eval &block
  end

  def add_item(path, item)
    if path.length > 1
      case @files[path[0..-2]]
      when ValiseWorks::Directory
      when nil
        add_dir(path[0..-2])
      else
        raise "Tried to add items below #{path[0..-2]} which is not a directory"
      end
    end
    @files[path] = item
  end

  def add_dir(path)
    add_item(path, ValiseWorks::Directory.new(path))
  end

  def add_file(path, data = nil)
    add_item(path, ValiseWorks::File.new(path, data))
  end

  def yaml_file(name)
    path = @prefix + [name.to_s]
    @files[path] = ValiseWorks::YAMLFile::new(path, yield )
  end

  def dir(name)
    path = @prefix + [name]
    add_dir(path)
    @prefix.push(name)
    yield if block_given?
    @prefix.pop
  end

  def file(name, data=nil)
    path = @prefix + [name.to_s]
    add_file(path, data)
  end

  def align(string)
    lines = string.split(/\n/)
    first = lines.shift
    match = /^(\s*)<<</.match(first)
    unless(match.nil?)
      catch(:haircut) do
        return lines.map do |line|
          raise line if /^#{match[1]}|^\s*$/ !~ line
          throw :haircut if /^#{match[1]}|^\s*$/ !~ line
          line.sub(/^#{match[1]}/, "")
        end.join("\n")
      end
    end
    return string
  end

  private

  def path_split(path)
    path.split(::File::Separator)
  end

  def contents_from(*path)
    path = unpath(path)
    m = /(.*):\d+/.match(caller[0])
    dir = ::File::dirname(::File::expand_path(m[1]))

    file_path = ::File::join(unpath(dir), path)
    ::File::open(file_path, "r") do |file|
       file.read
    end
  end

end
