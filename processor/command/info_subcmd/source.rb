# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require 'pp'
begin
  require 'linecache'
rescue LoadError
  require 'linecache19'
end
require 'columnize'
require_relative '../base/subcmd'
require_relative '../../../app/complete'
require_relative '../../../app/run'

class Trepan::Subcommand::InfoSource < Trepan::Subcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    DEFAULT_FILE_ARGS = %w(size mtime sha1)

    HELP = <<-EOH
#{CMD} 

Show information about the current source file. 
EOH
    MAX_ARGS     = 0
    MIN_ABBREV   = 'so'.size  # Note we have "info frame"
    NEED_STACK   = true
  end

  # completion %w(all brkpts iseq sha1 size stat)

  include Trepanning

  # Get file information
  def run(args)
    if not @proc.frame
      errmsg('No frame - no default file.')
      return false
    end
    frame_file = @proc.frame.file
    filename = LineCache::unmap_file(frame_file) || File.expand_path(frame_file)
    canonic_name = @proc.canonic_file(filename)
    canonic_name = LineCache::unmap_file(canonic_name) || canonic_name
    m = filename
    if LineCache::cached?(canonic_name)
      m += ' is cached in debugger'
      if canonic_name != filename
        m += (' as:\n  ' + canonic_name)
      end
      m += '.'
      msg(m)
    end
    max_line = LineCache::size(canonic_name)
    msg 'File has %d lines.' % max_line if max_line
    msg('SHA1 is %s.' % LineCache::sha1(canonic_name))
    syntax_errors = Trepan::ruby_syntax_errors(canonic_name)
    if syntax_errors
      msg('Not a syntactically-correct Ruby program.')
    else    
      msg('Possible breakpoint line numbers:')
      lines = LineCache.trace_line_numbers(canonic_name)
      fmt_lines = columnize_numbers(lines)
      msg(fmt_lines)
    end
    msg("Stat info:\n\t%s" % LineCache::stat(canonic_name).pretty_inspect)
  end
end

if __FILE__ == $0
  if !(ARGV.size == 1 && ARGV[0] == 'noload')
    ISEQS__        = {}
    SCRIPT_ISEQS__ = {}
    ARGV[0..-1]    = ['noload']
    load(__FILE__)
  else    
    require_relative '../../mock'
    cmd = MockDebugger::sub_setup(Trepan::Subcommand::InfoSource, false)
    cmd.run(cmd.prefix)
  end
end
