# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subsubcmd'
require_relative '../base/subsubmgr'

class Trepan::SubSubcommand::ShowTrace < Trepan::SubSubcommandMgr 

  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP = "Show event tracing printing"
    MIN_ABBREV = 'tr'.size
    SHORT_HELP = HELP
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  dbgr = MockDebugger::MockDebugger.new
  cmds = dbgr.core.processor.commands
  show_cmd = cmds['show']
  command = Trepan::SubSubcommand::ShowTrace.new(dbgr.core.processor, 
                                                 show_cmd)

  name = File.basename(__FILE__, '.rb')
  cmd_args = ['show', name]
  command.run(cmd_args)
end
