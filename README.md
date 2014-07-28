[![Build Status](https://travis-ci.org/camertron/trie-file.svg?branch=master)](https://travis-ci.org/camertron/trie-file)

trie-file
=========

Memory-efficient cached trie and trie storage.

## Installation

`gem install trie-file`

Then, somewhere in your code:

```ruby
require 'trie-file'
```

## Rationale

trie-file contains two things: an implementation of the [trie data structure](http://en.wikipedia.org/wiki/Trie), and a way to write them to disk and read them back again. It tries (ha!) to do this in a memory-efficient way by packing the trie structure in a specialized binary form. This special packing method means the trie can be searched entirely _on disk_ without needing to load the whole structure into memory (linear time). Each key you look up is cached so subsequent accesses are even faster (constant time). trie-file is also capable of reading and writing entire trie structures.

Because tries (also known as prefix trees) rely on keys having common prefixes, you're required to use string keys. There are no type restrictions on values.

## What's a Trie?

For an in-depth explanation, see the Wikipedia link above. Essentially tries are key-value data structures that work similar to Ruby hashes. You add a key and a value to the trie and can later retrieve the value using the same key.

## Basic Usage

Create a trie and write it to disk:

```ruby
trie = TrieFile::Trie.new
trie.add('foo', 'bar')

TrieFile::File.open('/path/to/file', 'wb') do |f|
  f.write_trie(trie)
end
```

Open a file handle to a trie and search it _on disk_:

```ruby
trie_file = TrieFile::File.open('/path/to/file', 'rb')
trie_file.find('foo')  # => 'bar'
```

To read an entire trie, use the `#read` method instead of `#open`:

```ruby
trie = TrieFile::File.read('/path/to/file')
```

## Choosing a Hash Method

By default, trie-file does not hash your keys. Instead, it iterates over each character in the key and constructs the internal trie structure. trie-file also supports hashing keys with the md5 or sha1 algorithms to minimize your search space:

```ruby
trie = TrieFile::Trie.new(nil, :sha1)
```

If you wrote a trie to disk that was hashed using sha1, you'll need to supply an additional argument to `#open` and `#read`:

```ruby
trie_file = TrieFile::File.open('/path/to/file', 'rb', :sha1)
trie = TrieFile::File.read('/path/to/file', :sha1)
```

## Requirements

No external requirements.

## Running Tests

`bundle exec rspec` should do the trick :)

## Authors

* Cameron C. Dutro: http://github.com/camertron
