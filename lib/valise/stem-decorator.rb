module Valise
  class StemDecorator < SearchRoot
    def initialize(stem, search_root)
      @stem, @search_root = stem, search_root
    end
    attr_reader :stem, :search_root
    protected :stem, :search_root

    def initialize_copy(other)
      @stem = other.stem
      @search_root = other.search_root.dup
    end

    def segments
      @search_root.segments
    end

    def segments=(segments)
      @search_root.segments = segments
    end

    def stem_pattern
      (@stem + "**").to_s
    end

    def under_stem(path)
      segments = make_pathname(path)
      if path.fnmatch?(stem_pattern, File::FNM_DOTMATCH)
        return path.relative_path_from(@stem)
      else
        raise Errors::PathOutsideOfRoot
      end
    end

    def inspect
      "#{self.class.name.split(":").last}:[#{@stem.to_s}]#{@search_root.inspect}"
    end

    def each
      @search_root.each do |path|
        yield(@stem + path)
      end
    end

    def full_path(segments)
      segments = under_stem(segments)
      @search_root.full_path(segments)
    end

    def write(item)
      @search_root.write(item)
    end

    def writable?(segments)
      @search_root.writable?(under_stem(segments))
    rescue Errors::PathOutsideOfRoot
      return false
    end

    def present?(segments)
      @search_root.present?(under_stem(segments))
    rescue Errors::PathOutsideOfRoot
      return false
    end

    def get_from(item)
      @search_root.get_from(item)
    end
  end
end
