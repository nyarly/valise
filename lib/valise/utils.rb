require 'pathname'
require 'valise/errors'

module Valise
  module StringTools
    def align(string)
      lines = string.split(/\n/)
      first = lines.shift
      match = /^(\s*)<<</.match(first)
      unless(match.nil?)
        return lines.map do |line|
          unless /^#{match[1]}|^\s*$/ =~ line
            raise Errors::UnderIndented, line
          end
          line.sub(/^#{match[1]}/, "")
        end.join("\n")
      end
      return string
    end
    module_function :align
  end

  module Unpath
    extend self

    def file_from_backtrace(line)
      /(.*):\d+/.match(line)[1]
    end

    def from_here(rel_path, base_path = nil)
      base_path ||= file_from_backtrace(caller[0])
      make_pathname(base_path) + make_pathname(rel_path)
    end

    def starting_directory
      make_pathname(ENV['PWD'] || Dir.pwd)
      #Otherwise symlinks won't behave as expected
    end
    alias start_dir starting_directory

    def current_directory
      make_pathname(Dir.pwd)
    end

    def up_to(up_to=nil, base_path = nil)
      base_path ||= file_from_backtrace(caller[0])
      up_to ||= "lib"

      up_until(base_path, "Path with basename #{up_to.inspect}") do |path|
        path.basename.to_s == up_to
      end
    end

    class WorkspaceFinder
      include Unpath

      attr_accessor :search_from, :workspace_children, :description, :fallback

      def search_from
        @search_from ||= start_dir
      end

      def workspace_children
        @workspace_children ||= %w{.git .hg _MTN}
      end

      def description
        @description ||= "Version control workspace"
      end

      def search_start
        path = make_pathname(search_from)
        path = path.realpath unless path.absolute?
        path
      end

      def find
        up_until(search_start, description) do |path|
          path.children(false).any? do |child|
            workspace_children.any? do |vc_config|
              child.fnmatch? vc_config
            end
          end
        end
      rescue Errors::NoMatchingPath
        if fallback.nil?
          raise
        else
          fallback
        end
      end
    end

    def containing_workspace
      finder = WorkspaceFinder.new
      yield finder if block_given?
      finder.find
    end

    def up_until(base_path = nil, description=nil)
      base_path ||= file_from_backtrace(caller[0])
      make_pathname(base_path).ascend do |path|
        if yield(path)
          return path
        end
      end
      raise Errors::NoMatchingPath, "#{description || "Satisfactory path"} not found in #{base_path}"
    end

    def clean_pathname(pathname)
      pathname.sub(/^~[^#{File::Separator}]*/) do |homedir|
        File::expand_path(homedir)
      end.cleanpath
    end

    def make_pathname(parts)
      case parts
      when Pathname
        return clean_pathname(parts)
      when Array
        unless parts.any?{|part| not (String === part or Symbol === part)}
          parts = File::join(parts.map{|part| part.to_s})
        else
          raise ArgumentError, "path must be composed of strings or symbols"
        end
      when String
      when Symbol
        parts = parts.to_s
      when ::File
        parts = parts.path
      else
        raise ArgumentError, "path must be String, Array of Strings or File"
      end
      pathname = clean_pathname(Pathname.new(parts))
    end
  end
end
