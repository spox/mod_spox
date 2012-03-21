require 'splib'

module Splib
  Splib.load :Sleep

  # Used to wakeup timer
  class Wakeup < Exception
  end

  class BasicTimer
    # args:: Argument Hash
    #   :report_thread => Thread to send exceptions to (defaults to current)
    def initialize(args={})
      @items = {}
      @sleeping = false
      @report = args[:report_thread] ? args[:report_thread] : Thread.current
      @timer = Thread.new{ start_timer }
    end
    # args:: Argument hash
    #   :period => seconds to wait
    #   :once => only run once
    # block:: block to execute when wait is complete
    # Add new item to timer
    def add(args={}, &block)
      Thread.exclusive do
        @items[block] = {:remaining => args[:period].to_f, :reset => args[:once] ? 0 : args[:period].to_f}
      end
      retime
      block
    end

    # proc:: proc returned from the BasicTimer#add method
    # Remove item from timer
    def remove(proc)
      Thread.exclusive{ @items.delete(proc) }
      retime
    end

    private

    # Reset timer to current items registered
    def retime
      @timer.raise Wakeup.new if @sleeping
    end

    def min
      Thread.exclusive{ @items.values.map{|x|x[:remaining]}.min }
    end

    def tick(secs)
      completed = []
      delete = []
      @items.each_pair do |proc,times|
        @items[proc][:remaining] = times[:remaining].to_f - secs.to_f
        if(@items[proc][:remaining] <= 0)
          completed << proc
          if(@items[proc][:reset] > 0)
            @items[proc][:remaining] = @items[proc][:reset]
          else
            delete << proc
          end
        end
      end
      @items.delete_if{|k,v|delete.include?(k)}
      completed
    end

    def start_timer
      loop do
        begin
          Thread.exclusive{ @sleeping = true }
          time = Splib.sleep(min)
          Thread.exclusive do
            @sleeping = false
            tick(time).each do |proc|
              proc.call
            end
          end
        rescue Wakeup
          Thread.exclusive{ @sleeping = false }
          # ignore and carry on #
        rescue => e
          @report.raise e
          retry
        end
      end
    end
  end
end
