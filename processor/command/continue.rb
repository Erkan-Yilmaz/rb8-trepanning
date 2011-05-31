# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../stepping'

class Trepan::Command::ContinueCommand < Trepan::Command
  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
#{NAME} [LOCATION]

Leave the debugger loop and continue execution. Subsequent entry to
the debugger however may occur via breakpoints or explicit calls, or
exceptions.

If a parameter is given, a temporary breakpoint is set at that position
before continuing. 

Examples:
   #{NAME}
   #{NAME} 10    # continue to line 10

See also 'step', 'next', 'finish', 'nexti' commands and "help location".
    HELP

    ALIASES      = %w(c cont)
    CATEGORY     = 'running'
    MAX_ARGS     = 1  # Need at most this many
    NEED_RUNNING = true
    SHORT_HELP   = 'Continue execution of the debugged program'
  end

  # This is the method that runs the command
  def run(args)

    ## FIXME: DRY this code, tbreak and break.
    unless args.size == 1
      filename = @proc.frame.file
      line_number = @proc.get_an_int(args[1])
      return unless line_number
      unless LineCache.trace_line_numbers(filename).member?(line_number)
        errmsg("Line %d is not a stopping point in file \"%s\".\n" %
               [line_number, filename])
        return
      end
      @proc.state.context.set_breakpoint(filename, line_number)
    end
    @proc.continue
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  puts "To be continued..."
  exit
  p cmd.run([cmd.name])
end