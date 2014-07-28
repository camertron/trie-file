# encoding: UTF-8

require 'thread'

# root:
# 2b value length
# nb value
# 2b (number of children)
# children metadata:
#   3b letter
#   3b child location
# children:
#   node:
#     2b value length
#     ...

module TrieFile
  class File
    attr_reader :handle, :hash_mode

    def self.open(path, mode, hash_mode = :none)
      handle = ::File.open(path, mode)

      unless handle.binmode?
        raise ArgumentError, 'TrieFile must be opened in binary mode.'
      end

      file = new(handle, hash_mode)

      if block_given?
        yield file
        handle.close
      end

      file
    end

    def self.read(path)
      root = nil

      ::File.open(path, 'rb') do |io|
        root = read_node(io)
      end

      Trie.new(root)
    end

    def initialize(handle, hash_mode)
      @handle = handle
      @semaphore = Mutex.new
      @hash_mode = hash_mode
    end

    def write_trie(trie)
      mark(trie)
      self.class.write_node(trie.root, handle)
    end

    def find(key)
      if closed?
        raise IOError, 'file is not currently open.'
      end

      @semaphore.synchronize do
        key = hash_key(key)
        cache.fetch(key) do
          handle.seek(0, IO::SEEK_SET)
          value = nil

          key.each_char do |char|
            value, child_metadata = self.class.read_node_header(handle)
            metadata = child_metadata.find do |data|
              data.first == char
            end

            return nil unless metadata
            handle.seek(metadata.last, IO::SEEK_SET)
          end

          value = self.class.read_value(handle)
          cache[key] = value
          value
        end
      end
    end

    def closed?
      @handle.closed?
    end

    def close
      handle.close
    end

    private

    BYTE_LENGTH = 8
    LETTER_FIELD_LENGTH = 3
    POSITION_FIELD_LENGTH = 3
    POSITION_MAX = 2 ** (BYTE_LENGTH * POSITION_FIELD_LENGTH)
    VALUE_FIELD_LENGTH = 2
    CHILD_COUNT_FIELD_LENGTH = 2

    def hash_key(key)
      Trie.hash_key(key, hash_mode)
    end

    def cache
      @cache ||= {}
    end

    def mark(trie)
      mark_node(trie.root, 0)
    end

    def mark_node(node, byte_pos)
      node.byte_pos = byte_pos
      total_child_size = 0
      node.children.each_pair do |letter, child|
        offset = mark_node(child, byte_pos + node.bytesize + total_child_size)
        total_child_size += child.bytesize + offset
      end
      total_child_size
    end

    def self.read_value(io)
      # 2b value length
      value_bytesize = read_int(io, VALUE_FIELD_LENGTH)

      # nb value
      value = io.read(value_bytesize)
    end

    def self.read_node_header(io)
      value = read_value(io)

      # 2b number of children
      number_of_children = read_int(io, CHILD_COUNT_FIELD_LENGTH)

      child_metadata = number_of_children.times.map do
        # 2b letter
        letter = read_bytes(io, LETTER_FIELD_LENGTH)

        # 3b child location
        child_pos = read_int(io, POSITION_FIELD_LENGTH)
        [letter, child_pos]
      end

      [value, child_metadata]
    end

    def self.read_node(io)
      value, child_metadata = read_node_header(io)
      node = Node.new(value)

      child_metadata.each do |metadata|
        node.add_child(
          metadata.first,
          read_node(io)
        )
      end

      node
    end

    def self.write_node(node, io)
      # 2b value length
      write_int(io, node.value_bytesize, VALUE_FIELD_LENGTH)

      # nb value
      write_bytes(io, node.value_bytes.to_a)

      # 2b number of children
      write_int(io, node.children.size, CHILD_COUNT_FIELD_LENGTH)

      # children
      node.children.each_pair do |letter, child_node|
        # 2b letter
        if letter.bytesize > LETTER_FIELD_LENGTH
          raise "Letter #{letter} is larger than #{LETTER_FIELD_LENGTH} bytes."
        else
          write_bytes(io, letter.bytes.to_a, LETTER_FIELD_LENGTH)
        end

        # 3b child location
        if child_node.byte_pos > POSITION_MAX
          raise "Encountered write position greater than #{POSITION_FIELD_LENGTH} bytes."
        else
          write_int(io, child_node.byte_pos, POSITION_FIELD_LENGTH)
        end
      end

      node.children.each_pair do |letter, child_node|
        write_node(child_node, io)
      end
    end

    def self.write_int(io, int, bytesize = int_bytesize(int))
      actual_bytesize = int_bytesize(int)
      (bytesize - actual_bytesize).times { io.putc("\0") }

      actual_bytesize.times do |i|
        # putc always writes the LSB if given a multibyte arg
        io.putc(int >> ((actual_bytesize - i - 1) * BYTE_LENGTH))
      end
    end

    def self.int_bytesize(int)
      return 0 if int == 0
      (Math.log2(int) / BYTE_LENGTH).to_i + 1
    end

    def self.write_bytes(io, bytes, bytesize = bytes.size)
      (bytesize - bytes.size).times { io.putc("\0") }
      bytes.each { |byte| io.putc(byte) }
    end

    def self.read_int(io, bytesize)
      (bytesize - 1).downto(0).inject(0) do |sum, i|
        sum + (io.readbyte << (i * BYTE_LENGTH))
      end
    end

    def self.read_bytes(io, bytesize)
      # remove leading zero bytes
      bytes = bytesize.times.map { io.readbyte }
      return [0] if bytes.all? { |byte| byte == 0 }
      idx = bytes.find_index { |byte| byte != 0 }
      bytes[idx..-1].pack("U*")
    end
  end
end
