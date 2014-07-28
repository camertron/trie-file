$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'trie-file/version'

Gem::Specification.new do |s|
  s.name     = "trie-file"
  s.version  = ::TrieFile::VERSION
  s.authors  = ["Cameron Dutro"]
  s.email    = ["camertron@gmail.com"]
  s.homepage = "http://github.com/camertron"

  s.description = s.summary = "Memory-efficient cached trie and trie storage."

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true

  s.require_path = 'lib'
  s.files = Dir["{lib,spec}/**/*", "Gemfile", "History.txt", "README.md", "Rakefile", "trie-file.gemspec"]
end
