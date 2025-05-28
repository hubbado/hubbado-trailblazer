ENV["CONSOLE_DEVICE"] ||= "stdout"
ENV["LOG_LEVEL"] ||= "_min"

puts RUBY_DESCRIPTION

puts
puts "TEST_BENCH_DETAIL: #{ENV["TEST_BENCH_DETAIL"].inspect}"
puts

require_relative "../init.rb"

require "reform"
require "reform/form/dry"
Reform::Form.class_eval do
  feature Reform::Form::Dry
end

require "trailblazer-macro"
require "trailblazer-macro-contract"
require "test_bench"; TestBench.activate
require "debug"

include Hubbado::Trailblazer
