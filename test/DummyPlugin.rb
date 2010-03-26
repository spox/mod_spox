class Plug < ModSpox::Plugin
    # overload destroy and don't call
    # super so we don't have to actually
    # load up a pipeline
    def destroy
    end
end