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
    def unpath(parts)
      if Array === parts and parts.length == 1
        parts = parts[0]
      end

      case parts
      when Array
        if (parts.find{|part| not (String === part or Symbol === part)}.nil?)
          parts = parts.map{|part| part.to_s}
        else
          raise ArgumentError, "path must be composed of strings or symbols"
        end
      when String
        parts = parts.split(::File::Separator)
      when Symbol
        parts = [parts.to_s]
      when ::File
        parts = parts.path
        parts = parts.split(::File::Separator)
      else
        raise ArgumentError, "path must be String, Array of Strings or File"
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
