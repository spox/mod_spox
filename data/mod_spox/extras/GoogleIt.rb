class GoogleIt < ModSpox::Plugin
    def initialize(pipeline)
        super
        add_sig(:sig => 'googleit (.+)', :method => :git, :description => 'Let me google that for you', :params => [:term])
    end
    
    def git(m, params)
        link = "http://www.letmegooglethatforyou.com/?q=#{URI.escape(params[:term])}"
        output = ["Oh please, let me google: \2#{params[:term]}\2 for you."]
        output << "\2Result:\2 #{Helpers.tinyurl(link)}"
        reply m.replyto, output
    end
end