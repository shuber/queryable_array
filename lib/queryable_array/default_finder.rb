class QueryableArray < Array
  # Allows objects to be searched by +default_finders+ thru <tt>[]</tt>. For example:
  #
  #   users = QueryableArray.new(User.all, :email)
  #   users['test@example.com']    # => #<User @email='test@example.com'>
  #   users['missing@domain.com']  # => nil
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

    # If +default_finders+ has been set and +key+ is not a +Fixnum+, +Range+,
    # or anything else natively supported by +Array+ then it loops thru each
    # +default_finders+ and returns the first matching result of +find_by(finder => key)+
    # or +find_all(finder => key.first)+ if +key+ is an +Array+. If +key+ is already
    # a +Hash+ or an +Array+ containing a +Hash+ then it acts like an alias for +find_by+
    # or +find_all+ respectively. It also accepts a +Proc+ or any object that responds to
    # +call+. It behaves exactly like its superclass +Array+ in all other cases.
    #
    #   pages = QueryableArray.new(Page.all, [:uri, :name])
    #
    #   pages['/']        # => #<Page @uri='/' @name='Home'>
    #   pages['Home']     # => #<Page @uri='/' @name='Home'>
    #   pages[/home/i]    # => #<Page @uri='/' @name='Home'>
    #   pages['missing']  # => nil
    #
    #   pages[[/users/i]]    # => [#<Page @uri='/users/bob' @name='Bob'>, #<Page @uri='/users/steve' @name='Steve'>]
    #   pages[[/missing/i]]  # => []
    #
    #   pages[proc { |page| page.uri == '/' }]         # => #<Page @uri='/' @name='Home'>
    #   pages[[proc { |page| page.uri =~ /users/i }]]  # => [#<Page @uri='/users/bob' @name='Bob'>, #<Page @uri='/users/steve' @name='Steve'>]
    def [](key)
      super
    rescue TypeError => error
      if default_finders.empty?
        raise error
      else
        method, key = key.is_a?(Array) ? [:find_all, key.first] : [:find_by, key]
        send method, &query(key)
      end
    end

    # Converts a search into a +Proc+ object that can be passed to +find_by+ or
    # +find_all+. If +search+ is a +Proc+ or an object that responds to +call+
    # then it is wrapped in a +Proc+ and returned. Otherwise the returned +Proc+
    # loops thru each +default_finders+ looking for a value that matches +search+.
    def query(search)
      Proc.new do |object|
        if search.respond_to?(:call)
          search.call object
        else
          default_finders.any? do |attribute|
            finder(attribute => search).call object
          end
        end
      end
    end
  end
end