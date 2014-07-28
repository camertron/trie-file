# encoding: UTF-8

require 'digest/md5'
require 'digest/sha1'

module TrieFile
  class Trie
    attr_reader :root, :hash_mode

    def initialize(root = nil, hash_mode = :none)
      @root = root || Node.new
      @hash_mode = hash_mode
    end

    def add(str, value)
      node = root
      key = hash_key(str)

      key.each_char do |char|
        if node.has_child?(char)
          node = node.child_at(char)
        else
          node = node.add_child(char, Node.new)
        end
      end

      node.value = value
    end

    def find(key)
      node = root
      hash_key(key).each_char do |char|
        node = node.child_at(char)
        return nil unless node
      end
      node.value
    end

    def hash_key(key)
      self.class.hash_key(key, hash_mode)
    end

    def self.hash_key(key, hash_mode)
      case hash_mode
        when :md5
          Digest::MD5.hexdigest(key)
        when :sha1
          Digest::SHA1.hexdigest(key)
        else
          key
      end
    end
  end
end
