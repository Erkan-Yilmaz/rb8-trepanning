# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../command'
require_relative '../../app/complete'

class Trepan::Command::UnaliasCommand < Trepan::Command

  unless defined?(HELP)
    HELP = <<-HELP
unalias ALIAS

Remove alias ALIAS

See also 'alias'.
HELP

    CATEGORY      = 'support'
    MIN_ARGS      = 1
    # MAX_ARGS      = 1  # Need at most this many
    NAME          = File.basename(__FILE__, '.rb')
    NEED_STACK    = true
    SHORT_HELP    = 'Remove an alias'
  end
  
  def complete(prefix)
    Trepan::Complete.complete_token(@proc.aliases.keys, prefix)
  end

  # Run command. 
  def run(args)
    args[1..-1].each do |arg|
      if @proc.aliases.member?(arg)
        @proc.aliases.delete(arg)
        msg "Alias for #{arg} removed."
      else
        msg "No alias found for #{arg}."
      end
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  cmd.run %w(cmd.name n)
  cmd.run %w(cmd.name n)
  cmd.run %w(cmd.name foo bar c)
end
