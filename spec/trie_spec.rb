# encoding: UTF-8

require 'spec_helper'

describe TrieFile::Trie do
  def trie
    TrieFile::Trie
  end

  describe '#add' do
    it 'should add the item' do
      trie.new.tap do |t|
        t.add('foo', 'bar')
        check_trie(t.root, 'foo', 'bar')
      end
    end

    it 'should hash the key with md5 if asked' do
      trie.new(nil, :md5).tap do |t|
        t.add('foo', 'bar')
        check_trie(
          t.root, Digest::MD5.hexdigest('foo'), 'bar'
        )
      end
    end

    it 'should hash the key with sha1 if asked' do
      trie.new(nil, :sha1).tap do |t|
        t.add('foo', 'bar')
        check_trie(
          t.root, Digest::SHA1.hexdigest('foo'), 'bar'
        )
      end
    end
  end

  describe '#find' do
    it 'should be able to find the item' do
      trie.new.tap do |t|
        t.add('foo', 'bar')
        expect(t.find('foo')).to eq('bar')
      end
    end

    it 'should be able to find the item using the md5 hash mode' do
      trie.new(nil, :md5).tap do |t|
        t.add('foo', 'bar')
        expect(t.find('foo')).to eq('bar')
      end
    end

    it 'should be able to find the item using the sha1 hash mode' do
      trie.new(nil, :sha1).tap do |t|
        t.add('foo', 'bar')
        expect(t.find('foo')).to eq('bar')
      end
    end
  end
end
