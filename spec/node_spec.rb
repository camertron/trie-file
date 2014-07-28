# encoding: UTF-8

require 'spec_helper'

describe TrieFile::Node do
  def create_node(value = nil)
    node = TrieFile::Node.new(value)
    yield node if block_given?
    node
  end

  def header_field_length
    TrieFile::Node::HEADER_FIELD_LENGTH
  end

  def child_fields_length
    TrieFile::Node::CHILD_FIELDS_LENGTH
  end

  describe '#has_child?' do
    it 'returns true if the node contains the child, false otherwise' do
      node = create_node do |node|
        node.add_child('a', create_node('foo'))
      end

      expect(node.has_child?('a')).to be(true)
      expect(node.has_child?('b')).to be(false)
    end
  end

  describe '#child_at' do
    it 'returns the child at the given letter, nil otherwise' do
      child = create_node('foo')
      node = create_node do |node|
        node.add_child('a', child)
      end

      expect(node.child_at('a')).to be(child)
      expect(node.child_at('b')).to be(nil)
    end
  end

  describe '#add_child' do
    it 'should add the child at the given letter' do
      node = create_node
      node.add_child('a', create_node('foo'))
      expect(node.children).to include('a')
      expect(node.children['a'].value).to eq('foo')
    end
  end

  describe '#bytesize' do
    it 'when no children and no value, returns just the header size' do
      expect(create_node.bytesize).to eq(header_field_length)
    end

    it 'when no children and a value, returns the header size plus the size of the value' do
      expect(create_node('foo').bytesize).to eq(header_field_length + 3)
    end

    it 'when a child and a value, returns the header size plus the size of the children plus the size of the value' do
      expect(
        create_node('foo') do |node|
          node.add_child('a', create_node('foo'))
        end.bytesize
      ).to eq(header_field_length + 3 + child_fields_length)
    end

    it 'when multiple children and a value, returns the header size plus the size of the children plus the size of the value' do
      expect(
        create_node('foo') do |node|
          node.add_child('a', create_node('foo'))
          node.add_child('b', create_node('bar'))
        end.bytesize
      ).to eq(header_field_length + 3 + child_fields_length * 2)
    end
  end

  describe '#value_bytesize' do
    it 'returns the number of bytes in the value' do
      expect(create_node('foo').value_bytesize).to eq(3)
    end

    it 'returns zero if the value is nil' do
      expect(create_node.value_bytesize).to eq(0)
    end
  end

  describe '#value_bytes' do
    it 'returns an enumerator of the bytes in the value' do
      expect(create_node('foo').value_bytes.to_a).to eq([102, 111, 111])
    end

    it 'returns an empty array if the value is nil' do
      expect(create_node.value_bytes).to eq([])
    end
  end
end
