require 'mixlib/shellout'
require 'stringio'

require 'shellfold/version'

module Shellfold
  class Command
    include MonitorMixin

    attr_reader :command
    attr_reader :desc
    attr_reader :out
    attr_reader :live_log
    attr_reader :log_failure
    attr_reader :last_output_max

    def initialize(*args, desc: nil,
                          out: $stdout,
                          live_log: false,
                          log_failure: false,
                          last_output_max: 200, **kwargs)
      super()

      kwargs.merge!(live_stderr: out, live_stdout: out) if live_log

      @command = Mixlib::ShellOut.new(*args, **kwargs)
      @desc = desc || command.command
      @desc_given = !!desc
      @out = out
      @live_log = live_log
      @log_failure = log_failure
      @last_output_max = last_output_max
      @running = false
    end

    def desc_given?
      @desc_given
    end

    def run
      running!

      progress_bar_thr = nil

      if live_log
        write_out{[desc_given? ? "#{desc} " : nil, "[#{command.command}]", "\n"].compact.join}
      else
        write_out{"   " + desc + "\n"}
        progress_bar_thr = Thread.new do
          loop do
            sleep 10
            break unless running?
            write_out{"   .\n"}
          end
        end
      end

      on_command_finish = proc do
        next if live_log
        if not command.status.success?
          write_out{"=> #{desc} [FAILED: #{command.status.inspect}]"}
          if log_failure
            msg = ["# COMMAND: #{command.command}\n",
                   "# LAST OUTPUT BEGIN:\n",
                   *[*command.stdout.lines,
                     *command.stderr.lines].last(last_output_max),
                   "# LAST OUTPUT END\n"].join
            write_out{"\n#{msg}"}
          else
            write_out{"\n"}
          end
        else
          write_out{"=> #{desc} [DONE]\n"}
        end
      end

      begin
        command.run_command
        stopped!
        on_command_finish.call
      rescue Mixlib::ShellOut::CommandTimeout
        on_command_finish.call
      ensure
        progress_bar_thr.kill if progress_bar_thr
      end

      command
    end

    def running?
      synchronize{ @running }
    end

    private

    def write_out(&blk)
      synchronize{ out.write(blk.call) }
    end

    def running!
      synchronize{ @running = true }
    end

    def stopped!
      synchronize{ @running = false }
    end
  end # Command

  class << self
    def run(*args, **kwargs)
      Command.new(*args, **kwargs).run
    end

    def run!(*args, **kwargs)
      Command.new(*args, log_failure: true, **kwargs).run
    end
  end # << self
end # Shellfold
