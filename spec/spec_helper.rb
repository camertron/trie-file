# encoding: UTF-8

require 'rspec'
require 'trie-file'
require 'pry-nav'

RSpec.configure do |config|
  config.mock_with :rr
end

def check_trie(root, key, val)
  node = root
  key.each_char do |char|
    expect(node.children.size).to eq(1)
    expect(node.children).to include(char)
    node = node.children[char]
  end
  expect(node.value).to eq(val)
end
