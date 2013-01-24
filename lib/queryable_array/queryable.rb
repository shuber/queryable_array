class QueryableArray < Array
  module Queryable
    # If +key+ is a +Hash+ or an +Array+ containing one
    # then it acts like an alias for +find_by+ or +find_all+ respectively. It
    # behaves exactly like its superclass +Array+ in all other cases.
    #
    #   pages = QueryableArray.new Page.all
    #
    #   pages[uri: '/']                # => #<Page @uri='/' @name='Home'>
    #   pages[uri: '/', name: 'Home']  # => #<Page @uri='/' @name='Home'>
    #   pages[uri: '/', name: 'Typo']  # => nil
    #
    #   pages[[uri: '/']]                # => [#<Page @uri='/' @name='Home'>]
    #   pages[[uri: '/', name: 'Typo']]  # => []
    def [](key)
      # Try to handle numeric indexes, ranges, and anything else that is
      # natively supported by Array first
      super
    rescue TypeError => error
      method, key = key.is_a?(Array) ? [:find_all, key.first] : [:find_by, key]
      key.is_a?(Hash) ? send(method, key) : raise(error)
    end

    # Returns a QueryableArray of objects matching +search+ criteria. When a +block+
    # is specified, it behaves exactly like +Enumerable#find_all+. Otherwise the
    # +search+ hash is converted into a +finder+ proc and passed as the block 
    # argument to +Enumerable#find_all+.
    #
    #   users.find_all(age: 30)                  # => [#<User @age=30>, #<User @age=30>, ...]
    #   users.find_all(name: 'missing')          # => []
    #   users.find_all { |user| user.age < 30 }  # => [#<User @age=22>, #<User @age=26>, ...]
    def find_all(search = {}, &block)
      block = finder search unless block_given?
      self.class.new super(&block), default_finders
    end

    # Behaves exactly like +find_all+ but only returns the first match. If no match
    # is found then +nil+ is returned.
    #
    #   users.find_by(age: 25)          # => #<User @age=25>
    #   users.find_by(name: 'missing')  # => nil
    def find_by(search = {}, &block)
      block = finder search unless block_given?
      find(&block)
    end

    # Accepts a +search+ hash and returns a +Proc+ which determines if all of an
    # object's attributes match their expected search values. It can be used as
    # the block arguments for +find+, +find_by+ and +find_all+.
    #
    #   query = finder name: 'bob'     # => proc { |user| user.name == 'bob' }
    #   query User.new(name: 'steve')  # => false
    #   query User.new(name: 'bob')    # => true
    #
    #   users.find(&query)             # => #<User @name='bob'>
    def finder(search)
      Proc.new do |object|
        search.all? do |attribute, expected|
          value = object.send attribute if object.respond_to?(attribute)
          expected == value || expected === value
        end
      end
    end
  end
end