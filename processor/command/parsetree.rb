# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
begin
  require 'rubygems'; require 'require_relative'
  require 'parse_tree'
  require_relative 'base/cmd'
  require_relative '../../app/cmd_parse'
  class Trepan::Command::ParseTreeCommand < Trepan::Command
    
    unless defined?(HELP)
      NAME = File.basename(__FILE__, '.rb')
      HELP = <<-HELP
#{NAME}
#{NAME}  method

In the first form, print a ParseTree S-expression of the current 
class. 
In the second form, preint a ParseTree S-expression of the current method.
In the third form print a ParseTree S-expression of CLASS.
In the fourth form, print a ParseTree S-expression of the given method.
HELP

    # ALIASES       = %w(p)
      CATEGORY      = 'data'
      SHORT_HELP    = 'PrettyPrint a ParseTree S-expression'
    end
    
    def run(args)
      meth = nil
      case args.size
      when 1
        method_name = @proc.frame.method_name
      when 2
        method_name = args[1]
      else
        errmsg 'Expecting a method name'
      end
      meth = Trepan::CmdParser.meth_for_string(method_name, @proc.frame.binding)
      if meth and meth.kind_of?(Method)
        p [meth, meth.name, meth.owner]
        msg ParseTree.translate(meth.owner, meth.name.to_sym).pretty_inspect
      end
    end

    if __FILE__ == $0
      require 'pp'
      require_relative '../mock'
      dbgr, cmd = MockDebugger::setup
      cmd.proc.frame_setup(Debugger.current_context, nil)
      cmd.proc.frame.instance_variable_set('@binding', TOPLEVEL_BINDING)
      cmd.run([cmd.name, 'FileUtils.rm'])
    end
    
  end
rescue LoadError
end
