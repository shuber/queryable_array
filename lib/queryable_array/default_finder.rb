class QueryableArray < Array
  module DefaultFinder
    attr_accessor :default_finders

    # Accepts an initial +array+ which defaults to +[]+. An optional +default_finders+
    # may also be specified as the second argument which is used in +QueryableArray#[]+
    # for quick lookups. It defaults to +nil+ which disables this behavior. See the
    # +QueryableArray#[]+ method for more documentation.
    def initialize(array = [], default_finders = nil)
      super array
      self.default_finders = Array(default_finders)
    end

    # If +default_finders+ has been set and +key+ is not a +Fixnum+ then it
    # loops thru each +default_finders+ and returns the first matching result
    # of +find_by(finder => key)+ or +find_all(finder => key.first)+ if +key+
    # is an +Array+. If +key+ is already a +Hash+ or an +Array+ containing one
    # then it acts like an alias for +find_by+ or +find_all+ respectively. It
    # behaves exactly like its superclass +Array+ in all other cases.
    #
    #   pages = QueryableArray.new(Page.all, [:uri, :name])
    #
    #   pages['/']        # => #<Page @uri='/'>
    #   pages['Home']     # => #<Page @name='Home'>
    #   pages[/home/i]    # => #<Page @name='Home'>
    #   pages['missing']  # => nil
    def [](key)
      super
    rescue TypeError => error
      if default_finders.empty?
        raise error
      else
        method, key = key.is_a?(Array) ? [:find_all, key.first] : [:find_by, key]
        send method do |object|
          default_finders.any? do |attribute|
            finder(attribute => key).call object
          end
        end
      end
    end
  end
end