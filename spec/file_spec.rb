# encoding: UTF-8

require 'spec_helper'

describe TrieFile::File do
  def file
    TrieFile::File
  end

  def trie
    TrieFile::Trie
  end

  let(:tmpdir) { './' }
  let(:tmpfile) { File.join(tmpdir, 'test.txt') }

  after(:each) do
    File.unlink(tmpfile) if File.exist?(tmpfile)
  end

  describe 'self#open' do
    it "raises an exception if the file isn't opened in binary mode" do
      proc = lambda { file.open(tmpfile, 'w') }
      expect(proc).to raise_error(ArgumentError, 'TrieFile must be opened in binary mode.')
    end

    it 'yields the file when a block is given and closes then returns it afterwards' do
      f = file.open(tmpfile, 'wb') do |f|
        expect(f).to be_a(file)
        expect(f).to respond_to(:write_trie)
        expect(f).to_not be_closed
      end

      expect(f).to be_a(file)
      expect(f).to respond_to(:write_trie)
      expect(f).to be_closed
    end

    it 'returns the open file when a block is not given' do
      file.open(tmpfile, 'wb').tap do |f|
        expect(f).to be_a(file)
        expect(f).to_not be_closed
      end
    end

    it 'uses the given hash mode when passed' do
      file.open(tmpfile, 'wb') do |f|
        f.write_trie(trie.new(nil, :md5).tap { |t| t.add('foo', 'bar') })
      end

      f = file.open(tmpfile, 'rb', :md5)
      expect(f.find('foo')).to eq('bar')
      f.close
    end
  end

  describe 'self#read' do
    let(:bytes) do
      [
        0, 0, 0, 1, 0, 0, 102, 0, 0, 10, 0, 0, 0, 1, 0, 0, 111, 0, 0,
        20, 0, 0, 0, 1, 0, 0, 111, 0, 0, 30, 0, 3, 98, 97, 114, 0, 0
      ]
    end

    let(:sha1_bytes) do
      [
        0, 0, 0, 1, 0, 0, 48, 0, 0, 10, 0, 0, 0, 1, 0, 0, 98, 0, 0, 20,
        0, 0, 0, 1, 0, 0, 101, 0, 0, 30, 0, 0, 0, 1, 0, 0, 101, 0, 0, 40,
        0, 0, 0, 1, 0, 0, 99, 0, 0, 50, 0, 0, 0, 1, 0, 0, 55, 0, 0, 60,
        0, 0, 0, 1, 0, 0, 98, 0, 0, 70, 0, 0, 0, 1, 0, 0, 53, 0, 0, 80,
        0, 0, 0, 1, 0, 0, 101, 0, 0, 90, 0, 0, 0, 1, 0, 0, 97, 0, 0, 100,
        0, 0, 0, 1, 0, 0, 51, 0, 0, 110, 0, 0, 0, 1, 0, 0, 102, 0, 0, 120,
        0, 0, 0, 1, 0, 0, 48, 0, 0, 130, 0, 0, 0, 1, 0, 0, 102, 0, 0, 140,
        0, 0, 0, 1, 0, 0, 100, 0, 0, 150, 0, 0, 0, 1, 0, 0, 98, 0, 0, 160,
        0, 0, 0, 1, 0, 0, 99, 0, 0, 170, 0, 0, 0, 1, 0, 0, 57, 0, 0, 180,
        0, 0, 0, 1, 0, 0, 53, 0, 0, 190, 0, 0, 0, 1, 0, 0, 100, 0, 0, 200,
        0, 0, 0, 1, 0, 0, 48, 0, 0, 210, 0, 0, 0, 1, 0, 0, 100, 0, 0, 220,
        0, 0, 0, 1, 0, 0, 100, 0, 0, 230, 0, 0, 0, 1, 0, 0, 52, 0, 0, 240,
        0, 0, 0, 1, 0, 0, 55, 0, 0, 250, 0, 0, 0, 1, 0, 0, 102, 0, 1, 4, 0,
        0, 0, 1, 0, 0, 51, 0, 1, 14, 0, 0, 0, 1, 0, 0, 99, 0, 1, 24, 0, 0,
        0, 1, 0, 0, 53, 0, 1, 34, 0, 0, 0, 1, 0, 0, 98, 0, 1, 44, 0, 0, 0,
        1, 0, 0, 99, 0, 1, 54, 0, 0, 0, 1, 0, 0, 50, 0, 1, 64, 0, 0, 0, 1,
        0, 0, 55, 0, 1, 74, 0, 0, 0, 1, 0, 0, 53, 0, 1, 84, 0, 0, 0, 1, 0,
        0, 100, 0, 1, 94, 0, 0, 0, 1, 0, 0, 97, 0, 1, 104, 0, 0, 0, 1, 0,
        0, 56, 0, 1, 114, 0, 0, 0, 1, 0, 0, 97, 0, 1, 124, 0, 0, 0, 1, 0,
        0, 51, 0, 1, 134, 0, 0, 0, 1, 0, 0, 51, 0, 1, 144, 0, 3, 98, 97,
        114, 0, 0
      ]
    end

    it 'reads a trie from disk' do
      File.open(tmpfile, 'wb') do |f|
        bytes.each { |byte| f.putc(byte) }
      end

      t = file.read(tmpfile)
      check_trie(t.root, 'foo', 'bar')
      expect(t.find('foo')).to eq('bar')
    end

    it 'reads a sha1-hashed trie from disk' do
      File.open(tmpfile, 'wb') do |f|
        sha1_bytes.each { |byte| f.putc(byte) }
      end

      t = file.read(tmpfile)
      expect(t.find('foo')).to be_nil

      t = file.read(tmpfile, :sha1)
      check_trie(t.root, Digest::SHA1.hexdigest('foo'), 'bar')
      expect(t.find('foo')).to eq('bar')
    end
  end

  describe '#write_trie' do
    it 'should write the trie to disk' do
      file.open(tmpfile, 'wb') do |f|
        f.write_trie(trie.new.tap { |t| t.add('foo', 'bar') })
      end

      t = file.read(tmpfile)
      check_trie(t.root, 'foo', 'bar')
      expect(t.find('foo')).to eq('bar')
    end

    it 'uses the given hash mode when passed' do
      file.open(tmpfile, 'wb') do |f|
        f.write_trie(trie.new(nil, :md5).tap { |t| t.add('foo', 'bar') })
      end

      t = file.read(tmpfile)
      check_trie(t.root, Digest::MD5.hexdigest('foo'), 'bar')
    end
  end

  describe '#find' do
    it 'should traverse the file on disk and find the value' do
      file.open(tmpfile, 'wb') do |f|
        f.write_trie(trie.new.tap { |t| t.add('foo', 'bar') })
      end

      # notice we're calling 'open' instead of 'read'
      f = file.open(tmpfile, 'rb')
      expect(f.find('foo')).to eq('bar')
      f.close
    end

    it 'raises an error if the file is already closed, eg. if open is called with a block' do
      File.open(tmpfile, 'w+') { |f| f.write('test') }
      f = file.open(tmpfile, 'rb') {}
      expect(lambda { f.find('foo') }).to raise_error(IOError, 'file is not currently open.')
    end
  end
end
