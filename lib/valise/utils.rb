require 'pathname'

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
    def string_to_segments(string)
      return string if string.empty?
      string.split(::File::Separator)
    end

    def file_from_backtrace(line)
      /(.*):\d+/.match(line)[1]
    end

    def from_here(rel_path, base_path = nil)
      base_path ||= file_from_backtrace(caller[0])
      make_pathname(base_path) + make_pathname(rel_path)
    end

    def up_to(up_to = nil, base_path = nil)
      base_path ||= file_from_backtrace(caller[0])
      up_to ||= "lib"

      abs_path = File::expand_path(base_path)
      base_path = make_pathname(base_path)

      base_path.ascend do |path|
        if path.basename.to_s == up_to
          return path
        end
      end

      raise "Relative root #{up_to.inspect} not found in #{abs_path.inspect}"
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

    module_function :from_here, :up_to, :string_to_segments, :file_from_backtrace, :make_pathname, :clean_pathname
    public :from_here, :up_to, :file_from_backtrace
  end
end
