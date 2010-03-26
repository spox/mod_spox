class Plug < ModSpox::Plugin
    attr_accessor :var
    def initialize(*args)
        super
        @var = nil
    end
    # overload destroy and don't call
    # super so we don't have to actually
    # load up a pipeline
    def destroy
    end
end