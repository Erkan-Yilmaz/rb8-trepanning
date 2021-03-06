#!/usr/bin/env ruby
require 'test/unit'
require 'stringio'
require 'tempfile'
require 'rubygems'; require 'require_relative'
require_relative '../../app/options'

# To have something to work with.
load 'tmpdir.rb'

class TestAppOptions < Test::Unit::TestCase

  def setup
    @options = Trepan::DEFAULT_CMDLINE_SETTINGS.clone
    @stderr  = StringIO.new
    @stdout  = StringIO.new
    @options = Trepan::copy_default_options
    @opts    = Trepan::setup_options(@options, @stdout, @stderr)
  end

  def test_cd
    rest = @opts.parse(['--cd', Dir.tmpdir])
    assert_equal(Dir.tmpdir, @options[:chdir])
    assert_equal('', @stderr.string)
    assert_equal('', @stdout.string)

    setup
    tf    = Tempfile.new("delete-me")
    orig_cd = @options[:chdir]
    rest = @opts.parse(['--cd', tf.path])
    assert_equal(orig_cd, @options[:chdir])
    assert_not_equal('', @stderr.string)
    assert_equal('', @stdout.string)
    File.unlink tf.path
    # FIXME: add test where directory isn't executable.
  end

  def test_binary_opts
    %w(nx readline).each do |name|
      setup
      o    = ["--#{name}"]
      rest = @opts.parse o
      assert_equal('', @stderr.string)
      assert_equal(true, @options[name.to_sym])
    end
    # --no- options
    %w(readline).each do |name|
      o    = ["--no-#{name}"]
      rest = @opts.parse o
      assert_equal('', @stderr.string)
      assert_equal(false, @options[name.to_sym])
    end
  end

  def no_test_help_and_version_opts
    omit unless Process.respond_to?(:fork) 
    Process.fork {
      %w(help version).each do |name|
        setup
        o    = ["--#{name}"]
        rest = @opts.parse o
        assert_not_equal('', @stdout.string)
        assert_equal('', @stderr.string)
        assert_equal(true, @options[name.to_sym])
        other_sym = 'help' == name ? :version : :help
        assert_equal(false, @options.member?(other_sym))
      end
    }
  end

  def test_both_client_server_opts
    # Try each of --client and --server options separately
    %w(client server).each do |name|
      setup
      o    = ["--#{name}"]
      rest = @opts.parse o
      assert_equal('', @stdout.string)
      assert_equal('', @stderr.string)
      assert_equal(true, @options[name.to_sym])
    end

    # Try both --client and --server together. Should give a warning
    setup
    o    = %w(--client  --server)
    rest = @opts.parse o
    assert_not_equal('', @stderr.string)
    assert_equal('', @stdout.string)
    assert_equal(true, @options[:client])
    ## FIXME - reinstate
    ## assert_equal(false, @options[:server])
    
  end

end
