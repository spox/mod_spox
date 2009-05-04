require 'mod_spox/handlers/Handler'
module ModSpox
    module Handlers
        class Kick < Handler
            def initialize(handlers)
                handlers[:KICK] = self
            end
            def process(string)
                if(string =~ /^:(\S+)\sKICK\s(\S+)\s(\S+)\s:(.+)$/)
                    source = $1
                    chan = $2
                    kicked = $3
                    reason = $4
                    kicker = find_model(source.gsub(/!.+$/, ''))
                    channel = find_model(chan)
                    kickee = find_model(kicked)
                    channel.remove_nick(kickee)
                    kickee.visible = false if kickee.channels.empty?
                    channel.parked = false if kickee.botnick == true
                    kickee.save_changes
                    channel.save_changes
                    return Messages::Incoming::Kick.new(string, channel, kicker, kickee, reason)
                else
                    Logger.warn('Failed to process KICK message')
                    return nil
                end
            end
        end
    end
end