class Filters < ModSpox::Plugin
    
    def initialize(pipeline)
        super
        group = Models::Group.filter(:name => 'admin').first
        add_sig(:sig => 'filter (in|out) list', :method => :list, :group => group, :desc => 'List enabled filters', :params => [:direction])
        add_sig(:sig => 'filter (in|out) add (\S+) (.+)', :method => :add, :group => group, :params => [:direction, :name, :code], :desc => 'Add new filter')
        add_sig(:sig => 'filter (in|out) remove (\S+)', :method => :remove, :group => group, :params => [:direction, :name], :desc => 'Remove filter')
        add_sig(:sig => 'filter (in|out) show (\S+)', :method => :show, :group => group, :params => [:direction, :name], :desc => 'Show the contents of the filter')
        @filters = {}
#        @filters[:in] = RubyFilter.new(Messages::Incoming::Privmsg)
#        @filters[:out] = RubyFilter.new(Messages::Outgoing::Privmsg)
        load_strings
        @filters[:in] = @filter_strings[:in]
        @filters[:out] = @filter_strings[:out]
        @pipeline << ModSpox::Messages::Internal::FilterAdd.new(@filters[:out], ModSpox::Messages::Incoming::Privmsg)
        @pipeline << ModSpox::Messages::Internal::FilterAdd.new(@filters[:out], ModSpox::Messages::Outgoing::Privmsg)
    end
#     
#     def add(m, params)
#         begin
#             name = params[:name].to_sym
#             direction = params[:direction].to_sym
#             raise "Key is already in use. Please choose another name (#{name})" if @filter_strings[direction][name]
#             @filter_strings[direction][name] = params[:code]
#             @filters[direction].filters = @filter_strings[direction]
#             save_strings
#             information m.replyto, "New filter has been applied under name: #{name}"
#         rescue Object => boom
#             error m.replyto, "Failed to apply new filter string under name: #{name}. Reason: #{boom}"
#         end
#     end
# 
#     def remove(m, params)
#         begin
#             name = params[:name].to_sym
#             direction = params[:direction].to_sym
#             raise "Failed to locate filter key: #{name}" unless @filters[direction][name]
#             @filters_strings[direction].delete(name)
#             @filters[direction].filters = @filter_strings[direction]
#             save_strings
#             information m.replyto, "Filter #{name} has been removed"
#         rescue Object => boom
#             error m.replyto, "Failed to remove filter named: #{name}. Reason: #{boom}"
#         end
#     end
# 
#     def list(m, params)
#         begin
#             direction = params[:direction].to_sym
#             if(@filters_strings[direction].empty?)
#                 warning m.replyto, 'There are currently no filters applied'
#             else
#                 information m.replyto, "Filters for #{direction}: #{@filter_strings[direction].keys.sort}"
#             end
#         rescue Object => boom
#             error m.replyto, "Failed to generate list. Reason: #{boom}"
#         end
#     end
# 
#     def show(m, params)
#         begin
#             direction = params[:direction].to_sym
#             name = params[:name].to_sym
#             if(@filter_strings[direction][name])
#                 information m.replyto, "#{name}: #{@filter_strings[direction][name]}"
#             else
#                 error m.replyto, "Failed to locate filter named: #{name}"
#             end
#         rescue Object => boom
#             error m.replyto, "Failed to locate filter. Reason: #{boom}"
#         end
#     end
# 
#     private
# 
    def load_strings
        @filter_strings = Models::Setting.find_or_create(:name => 'filters').value
        @filter_strings = {:in => {}, :out => {}} unless @filter_strings.is_a?(Hash)
    end
# 
#     def save_strings
#         v = Models::Setting.find_or_create(:name => 'filters')
#         v.value = @filter_strings
#         v.save
#     end
#     
#     class RubyFilter < ModSpox::Filter
#         def initialize(*args)
#             super
#             @filters = []
#         end
#         def filters
#             @filters
#         end
#         def filters=(f)
#             raise ArgumentError.new('Array of filter strings required') unless f.is_a?(Array)
#             @filters = f.dup
#         end
#         def filter(m)
#             @filters.each do |f|
#                 begin
#                     Kernel.eval(f)
#                 rescue Object
#                     ignore failures
#                 end
#             end
#         end
#     end
        
end