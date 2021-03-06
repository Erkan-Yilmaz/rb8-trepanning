# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../command'

# up command. Like 'down' but the direction (set by DIRECTION) is different.
#
# NOTE: The down command  subclasses this, so beware when changing! 
class Trepan::Command::UpCommand < Trepan::Command

  Trepan::Util.suppress_warnings {
    NAME        = File.basename(__FILE__, '.rb')
    HELP        = <<-HELP
#{NAME} [count]

Move the current frame up in the stack trace (to an older frame). 0 is
the most recent frame. If no count is given, move up 1.

See also 'down' and 'frame'.
  HELP

    ALIASES       = %w(u)
    CATEGORY      = 'stack'
    MAX_ARGS      = 1  # Need at most this many
    NEED_STACK    = true
    SHORT_HELP    = 'Move frame in the direction of the caller of the last-selected frame'
  }

  def complete(prefix)
    @proc.frame_complete(prefix, @direction)
  end
  
  def initialize(proc)
    super
    @direction = +1 # -1 for down.
  end

  # Run 'up' command.
  def run(args)

    # FIXME: move into @proc and test based on NEED_STACK.
    if @proc.stack_size == 0
      errmsg('No frames recorded.')
      return false
    end

    if args.size == 1
      # Form is: "up" which means "up 1"
      count = 1
    else
      count_str = args[1]
      name_or_id = args[1]
      low, high = @proc.frame_low_high(@direction)
      opts = {
        :msg_on_error =>
        "The '#{NAME}' command argument must eval to an integer. Got: %s" % count_str,
        :min_value => low, :max_value => high
      }
      count = @proc.get_an_int(count_str, opts)
      return false unless count
    end
    @proc.adjust_frame(@direction * count, false)
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  cmd.run [cmd.name]
end
