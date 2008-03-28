class BotNick < ModSpox::Plugin

    def initialize(pipeline)
        super(pipeline)
        @pipeline.hook(self, :shutdown, :Internal_Shutdown)
    end
    
    def shutdown(message)
        clear_nicks
    end
    
    private
    
    def clear_nicks
        Models::Nick.filter(:botnick => true).each{|nick| nick.botnick = false; nick.save}
    end

end