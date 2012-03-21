module ModSpox
module Plugins
  class Triggers < ModSpox::Plugin

    def setup
      @pipeline.hook(MessageFactory::Message, self, :parse){|m|m.type == :privmsg}
      @pipeline.hook(Hash, self, :register){|x| x[:trigger]||x[:signature]}
      load_triggers
      @triggers << '!'
      @signatures = []
    end

    def destroy
    end

    # m:: Hash
    # Registers a new trigger or signature
    # Hash format for adding triggers:
    # {:trigger => '!'}
    # Hash format for adding signatures:
    # {:signature => {:regexp => /regexp/,
    #         :matches => [:match1, :match2],
    #         :call => {:object => obj, :method => :name} OR lambda{|args|}
    #        }
    # }
    def register(m)
      Logger.debug "Received trigger registration hash: #{m}"
      if(m[:trigger])
        @triggers << m[:trigger]
        @triggers.uniq!
        @triggers.sort{|x,y|y.length <=> x.length}
        save(:triggers)
      end
      if(m[:signature])
        hash = {:regexp => m[:signature][:regexp]}
        hash[:matches] = m[:signature][:matches]
        if(m[:signature][:call].is_a?(Hash))
          hash[:send] = m[:signature][:call]
        elsif(m[:signature][:call].is_a?(Proc))
          hash[:call] = m[:signature][:call]
        else
          raise TypeError.new "I don't know what to do with: #{m[:signature][:call].class}"
        end
        @signatures << hash
      end
    end

    def parse(message)
      m = message.message.dup
      Logger.debug "Parsing message: #{message}"
      @triggers.each do |trigger|
        if(m[0, trigger.length] == trigger)
          Logger.debug "Trigger match on: #{trigger}"
          m.slice!(0, trigger.length)
          @signatures.each do |sig|
            Logger.debug "Checking message against signature: #{sig[:regexp]}"
            args = m.scan(sig[:regexp])
            unless(args.empty?)
              args = args[0]
              Logger.debug "Signature match on: #{sig[:regexp]}"
              args = Hash[sig[:matches].zip(args)]
              @pool.process do
                if(sig[:send])
                  sig[:send][:object].send(sig[:send][:method], message, args)
                elsif(hash[:call])
                  sig[:call].call(message, args)
                end
              end
            end
          end
        end
      end
    end

    private

    def save(*args)
      store = get_store
      store.transaction{ store[:triggers] = @triggers } if args.include?(:triggers)
      store.transaction{ store[:customs] = @custom_triggers} if args.include?(:customs)
    end
    
    def load_triggers
      store = get_store
      store.transaction do
        @triggers = store[:triggers]
        @custom_triggers = store[:customs]
      end
      @triggers = [] if @triggers.nil? || !@triggers.is_a?(Array)
      @custom_triggers = [] if @custom_triggers.nil? || !@custom_triggers.is_a?(Array)
    end

    def get_store
      PStore.new("#{ModSpox.config_dir}/triggers.pstore")
    end
  end
end
end