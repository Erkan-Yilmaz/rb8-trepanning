require 'rubygems'
require 'pp'
require 'stringio'
require 'socket'
require 'thread'
require 'ruby-debug-base'
require 'require_relative'
require_relative '../app/interface'
require_relative '../processor/processor'

module Trepan
  
  class << self
    attr_accessor :handler
    Trepan.handler = Debugger.handler = CommandProcessor.new
    # gdb-style annotation mode. Used in GNU Emacs interface
    attr_accessor :annotate

    # in remote mode, wait for the remote connection 
    attr_accessor :wait_connection

    # If set, a string to look for in caller() and is used to see
    # if the call stack is truncated.
    attr_accessor :start_sentinal 
    
    attr_reader :thread, :control_thread, :cmd_port, :ctrl_port

    def interface=(value) # :nodoc:
      handler.interface = value
    end

    # Trepan.start(options) -> bool
    # Trepan.start(options) { ... } -> obj
    #
    # If it's called without a block it returns +true+, unless debugger
    # was already started.  If a block is given, it starts debugger and
    # yields to block. When the block is finished executing it stops
    # the debugger with Trepan.stop method.
    #
    # If a block is given, it starts debugger and yields to block. When
    # the block is finished executing it stops the debugger with
    # Trepan.stop method. Inside the block you will probably want to
    # have a call to Trepan.debugger. For example:
    #
    #     Trepan.start{debugger; foo}  # Stop inside of foo
    #
    # Also, ruby-debug only allows
    # one invocation of debugger at a time; nested Trepan.start's
    # have no effect and you can't use this inside the debugger itself.
    #
    # <i>Note that if you want to stop debugger, you must call
    # Trepan.stop as many time as you called Trepan.start
    # method.</i>
    # 
    # +options+ is a hash used to set various debugging options.
    # Set :init true if you want to save ARGV and some variables which
    # make a debugger restart possible. Only the first time :init is set true
    # will values get set. Since ARGV is saved, you should make sure 
    # it hasn't been changed before the (first) call. 
    # Set :post_mortem true if you want to enter post-mortem debugging
    # on an uncaught exception. Once post-mortem debugging is set, it can't
    # be unset.
    def start(options={}, &block)
      options = Trepan::DEFAULT_START_SETTINGS.merge(options)
      if options[:init]
        Trepan.const_set('ARGV', ARGV.clone) unless 
          defined? Trepan::ARGV
        Trepan.const_set('PROG_SCRIPT', $0) unless 
          defined? Trepan::PROG_SCRIPT
        Trepan.const_set('INITIAL_DIR', Dir.pwd) unless 
          defined? Trepan::INITIAL_DIR
      end
      Trepan.tracing = options[:tracing] unless options[:tracing].nil?
      retval = Debugger.started? ? block && block.call(self) : Debugger.start_(&block) 
      if options[:post_mortem]
        post_mortem
      end
      return retval
    end
    
    def started?
      Debugger.started?
    end
    
    #
    # Starts a remote debugger.
    #
    def start_remote(host = nil, port = PORT, post_mortem = false)
      return if @thread
      return if started?

      self.interface = nil
      start
      self.post_mortem if post_mortem

      if port.kind_of?(Array)
        cmd_port, ctrl_port = port
      else
        cmd_port, ctrl_port = port, port + 1
      end

      ctrl_port = start_control(host, ctrl_port)
      
      yield if block_given?
      
      mutex = Mutex.new
      proceed = ConditionVariable.new
      
      server = TCPServer.new(host, cmd_port)
      @cmd_port = cmd_port = server.addr[1]
      @thread = Debugger::DebugThread.new do
        while (session = server.accept)
          self.interface = RemoteInterface.new(session)
          if wait_connection
            mutex.synchronize do
              proceed.signal
            end
          end
        end
      end
      if wait_connection
        mutex.synchronize do
          proceed.wait(mutex)
        end 
      end
    end
    alias start_server start_remote
    
    def start_control(host = nil, ctrl_port = PORT + 1) # :nodoc:
      raise "Debugger is not started" unless started?
      return @ctrl_port if defined?(@control_thread) && @control_thread
      server = TCPServer.new(host, ctrl_port)
      @ctrl_port = server.addr[1]
      @control_thread = Debugger::DebugThread.new do
        while (session = server.accept)
          interface = RemoteInterface.new(session)
          processor = ControlCommandProcessor.new(interface)
          processor.process_commands
        end
      end
      @ctrl_port
    end
    
    #
    # Connects to the remote debugger
    #
    def start_client(host = 'localhost', port = PORT)
      require "socket"
      interface = Trepan::LocalInterface.new
      socket = TCPSocket.new(host, port)
      puts "Connected."
      
      catch(:exit) do
        while (line = socket.gets)
          case line 
          when /^PROMPT (.*)$/
            input = interface.read_command($1)
            throw :exit unless input
            socket.puts input
          when /^CONFIRM (.*)$/
            input = interface.confirm($1)
            throw :exit unless input
            socket.puts input
          else
            print line
          end
        end
      end
      socket.close
    end
    
    # Runs normal debugger initialization scripts
    # Reads and executes the commands from init file (if any) in the
    # current working directory.  This is only done if the current
    # directory is different from your home directory.  Thus, you can
    # have more than one init file, one generic in your home directory,
    #  and another, specific to the program you are debugging, in the
    # directory where you invoke ruby-debug.
    def run_init_script(out = handler.interface)
      cwd_script_file  = File.expand_path(File.join(".", CMD_INITFILE_BASE))
      run_script(cwd_script_file, out) if File.exists?(cwd_script_file)

      home_script_file = File.expand_path(CMD_INITFILE)
      run_script(home_script_file, out) if File.exists?(home_script_file) and 
        cwd_script_file != home_script_file
    end

    #
    # Runs a script file
    #
    def run_script(file, out = handler.interface, verbose=false)
      interface = Trepan::ScriptInterface.new(File.expand_path(file), out)
      processor = Trepan::ControlCommandProcessor.new(interface)
      processor.process_commands(verbose)
    end
  end
end

module Kernel

  # Enters the debugger in the current thread after _steps_ line events occur.
  # Before entering the debugger startup script is read.
  #
  # Setting _steps_ to 0 will cause a break in the debugger subroutine
  # and not wait for a line event to occur. You will have to go "up 1"
  # in order to be back in your debugged program rather than the
  # debugger. Settings _steps_ to 0 could be useful you want to stop
  # right after the last statement in some scope, because the next
  # step will take you out of some scope.
  def debugger(steps = 1)
    Trepan.start unless Trepan.started?
    Trepan.run_init_script(StringIO.new)
    if 0 == steps
      Debugger.current_context.stop_frame = 0
    else
      Debugger.current_context.stop_next = steps
    end
  end
  alias breakpoint debugger unless respond_to?(:breakpoint)
end
