# encoding: UTF-8

module TrieFile
  class Node
    CHILD_FIELDS_LENGTH = 6
    HEADER_FIELD_LENGTH = 4

    attr_reader :children
    attr_accessor :value, :byte_pos

    def initialize(value = nil)
      @value = value
      @children = {}
      @byte_pos = 0
    end

    def has_child?(char)
      children.include?(char)
    end

    def child_at(char)
      children[char]
    end

    def add_child(char, node)
      @children[char] = node
    end

    def bytesize
      # add some constants here
      HEADER_FIELD_LENGTH + (children.size * CHILD_FIELDS_LENGTH) + value_bytesize
    end

    def value_bytesize
      value ? value.bytesize : 0
    end

    def value_bytes
      value ? value.bytes : []
    end
  end
end
