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
      string.split(::File::Separator)
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
        when '..'
          collapsed.pop
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
  end
end
