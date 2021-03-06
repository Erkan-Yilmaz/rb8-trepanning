require 'rubygems'; require 'require_relative'
require_relative '../app/default' # for Trepan::HOME_DIR etc.
require_relative 'virtual'
class Trepan::CmdProcessor < Trepan::VirtualCmdProcessor

  DEFAULT_SETTINGS = {
    :abbrev        => true,       # Allow abbreviations of debugger commands?
    :autoeval      => true,       # Ruby eval non-debugger commands
    :autoirb       => false,      # Go into IRB in debugger command loop
    :autolist      => false,      # Run 'list' 
    
    :basename      => false,      # Show basename of filenames only
    :callstyle     => :last,      # 
    :confirm       => true,       # Confirm potentially dangerous operations?
    :different     => 'nostack',  # stop *only* when  different position? 
    
    :debugdbgr     => false,      # Debugging the debugger
    :debugexcept   => true,       # Internal debugging of command exceptions
    :debugmacro    => false,      # debugging macros
    :debugskip     => false,      # Internal debugging of step/next skipping
    :directory     =>             # last-resort path-search for files
                  '$cdir:$cwd',   # that are not fully qualified.

    :hidestack     => nil,        # Fixnum. How many hidden outer
                                  # debugger stack frames to hide?
                                  # nil or -1 means compute value. 0
                                  # means hide none. Less than 0 means show
                                  # all stack entries.
    :hightlight    => false,      # Use terminal highlight? 
      
    :maxlist       => 10,         # Number of source lines to list 
    :maxstack      => 10,         # backtrace limit
    :maxstring     => 150,        # Strings which are larger than this
                                  # will be truncated to this length when
                                  # printed
    :maxwidth       => (ENV['COLUMNS'] || '80').to_i,
    :prompt         => 'trepan8', # core part of prompt. Additional info like
                                  # debug nesting and thread name is fixed
                                  # and added on.
    :reload         => false,     # Reread source file if we determine
                                  # it has changed?
    :save_cmdfile  => nil,        # If set, debugger command file to be
                                  # used on restart
    :timer         => false,      # show elapsed time between events
    :traceprint    => false,      # event tracing printing
    :tracebuffer   => false,      # save events to a trace buffer.
    :user_cmd_dir  => File.join(Trepan::HOME_DIR, 'trepan8', 'command'),
                                  # User command directory
  } unless defined? DEFAULT_SETTINGS
end

if __FILE__ == $0
  # Show it:
  require 'pp'
  PP.pp(Trepan::CmdProcessor::DEFAULT_SETTINGS)
end
