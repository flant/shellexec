require 'mixlib/shellout'
require 'stringio'

require 'shellfold/version'

module Shellfold
  class Command
    include MonitorMixin

    attr_reader :desc
    attr_reader :out
    attr_reader :out_bar
    attr_reader :command

    def initialize(*args, desc: "Running shell command", out: $stdout, **kwargs)
      super()

      @desc = desc
      @out = out
      @command = Mixlib::ShellOut.new(*args, **kwargs)
      @running = false
    end

    def run!
      run(ignore_failure: false)
    end

    def run(ignore_failure: true)
      running!
      write_out{"#{desc}"}

      thr = Thread.new do
        loop do
          sleep 10
          break unless running?
          write_out{' '} if not @been_here.tap{@been_here = true}
          write_out{'.'}
        end
      end

      begin
        command.run_command
        stopped!

        if not command.status.success?
          write_out{" [FAILED: #{command.status.inspect}]"}
          if ignore_failure
            write_out{"\n"}
          else
            msg = ["-" * 44, " LAST OUTPUT ", "-" * 44, "\n",
                   *[*command.stdout.lines,
                     *command.stderr.lines].reverse[0...2].reverse,
                   "-" * 101, "\n"].join
            write_out{"\n\n#{msg}"}
          end
        else
          write_out{" [DONE]\n"}
        end
      ensure
        thr.kill
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
    def run(*args)
      Command.new(*args).run
    end

    def run!(*args)
      Command.new(*args).run!
    end
  end # << self
end # Shellfold
