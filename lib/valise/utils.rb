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

  #XXX This has been overtaken by std-lib Pathname and should be mostly
  #refactored out
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
      repath(collapse(unpath(base_path) + unpath(rel_path)))
    end

    def up_to(up_to = nil, base_path = nil)
      base_path ||= file_from_backtrace(caller[0])
      up_to ||= "lib"

      abs_path = File::expand_path(base_path)
      base_path = unpath(base_path)
      until base_path.empty? or base_path.last == up_to
        base_path.pop
      end

      if base_path.empty?
        raise "Relative root #{up_to.inspect} not found in #{abs_path.inspect}"
      end

      return repath(base_path)
    end

    def unpath(parts)
      if Array === parts and parts.length == 1
        parts = parts[0]
      end

      case parts
      when Array
        if (parts.find{|part| not (String === part or Symbol === part)}.nil?)
          parts = parts.map{|part| string_to_segments(part.to_s)}.flatten
        else
          raise ArgumentError, "path must be composed of strings or symbols"
        end
      when String
        parts = string_to_segments(parts)
      when Symbol
        parts = string_to_segments(parts.to_s)
      when ::File
        parts = parts.path
        parts = parts.split(::File::Separator)
      else
        raise ArgumentError, "path must be String, Array of Strings or File"
      end

      if /^~/ =~ parts[0]
        parts = ::File::expand_path(parts[0]).split(::File::Separator) + parts[1..-1]
      end

      return parts
    end

    def collapse(segments)
      collapsed = []
      segments.each do |segment|
        case segment
        when '.'
        when ""
          if collapsed.empty?
            collapsed.push segment
          end
        when '..'
          if collapsed.empty?
            collapsed.push segment
          else
            collapsed.pop
          end
        else
          collapsed.push segment
        end
      end
      collapsed
    end

    def repath(segments)
      case segments
      when Array
        return segments.join(::File::Separator)
      when String
        return segments
      end
    end

    module_function :from_here, :up_to, :unpath, :repath, :string_to_segments, :file_from_backtrace
    public :from_here, :up_to, :file_from_backtrace
  end
end
