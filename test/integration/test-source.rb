#!/usr/bin/env ruby
require 'rubygems'; require 'require_relative'
# require_relative '../../lib/trepanning'
require_relative 'helper'

# Test 'source' command handling.
class TestSource < Test::Unit::TestCase
  include TestHelper
  def test_basic
    common_setup(__FILE__)
    Dir.chdir(@srcdir) do 
      assert_equal(true, 
                   run_debugger(@testname, @prefix + '../example/gcd.rb 3 5'))
    end
  end
end
