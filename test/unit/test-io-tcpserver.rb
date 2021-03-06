#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'

# Unit test for io/tcpserver.rb
require_relative '../../io/tcpfns'
require_relative '../../io/tcpserver'

class TestTCPDbgServer < Test::Unit::TestCase

  include Trepanning::TCPPacking

  def test_basic
    server = Trepan::TCPDbgServer.new
    begin
      server.open({ :open => false,
                    :port => 1027,
                    :host => '127.0.0.1'
                  })
    rescue
      puts "Skip #{__FILE__} because Port 1027 is in use"
      assert true
    end
    threads = []
    msgs = %w(one two three)
    Thread.new do
      msgs.each do |msg|
        begin
          line = server.read_msg.chomp
          assert_equal(msg, line)
        rescue EOFError
          puts 'Got EOF'
          break
        end
      end
    end
    threads << Thread.new do 
      t = TCPSocket.new('127.0.0.1', 1027)
      msgs.each do |msg|
        begin
          t.puts(pack_msg(msg))
        rescue EOFError
          puts "Got EOF"
          break
        rescue Exception => e
          puts "Got #{e}"
          break
        end
      end
      t.close
    end
    threads.each {|t| t.join }
    server.close
  end
end
