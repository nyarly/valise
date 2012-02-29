module Valise
  class StemDecorator < SearchRoot
    def initialize(stem, search_root)
      @stem, @search_root = stem, search_root
    end

    def under_stem(path)
      segments = unpath(path)
      top_part = segments[0...@stem.length]
      if top_part == @stem
        return segments[@stem.length..-1]
      else
        raise PathOutsideOfRoot
      end
    end

    def inspect
      "#{self.class.name.split(":").last}:[#{@stem.join("/")}]#{@search_root.inspect}"
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
    rescue PathOutsideOfRoot
      return false
    end

    def present?(segments)
      @search_root.present?(under_stem(segments))
    rescue PathOutsideOfRoot
      return false
    end

    def insert(item)
      @search_root.insert(item)
    end

    def get_from(item)
      @search_root.get_from(item)
    end
  end
end