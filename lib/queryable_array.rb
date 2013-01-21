# A +QueryableArray+ inherits from +Array+ and is intended to store a group of
# objects which share the same attributes allowing them to be searched. It
# overrides +[]+, +find_all+ and +method_missing+ to provide a simplified DSL
# for looking up objects by querying their attributes.
class QueryableArray < Array
  attr_accessor :default_finders

  # Accepts an initial +array+ which defaults to +[]+. An optional +default_finders+
  # may also be specified as the second argument which is used in +QueryableArray#[]+
  # for quick lookups. It defaults to +nil+ which disables this behavior. See the
  # +QueryableArray#[]+ method for more documentation.
  def initialize(array = [], default_finders = nil)
    super(array)
    self.default_finders = Array(default_finders)
  end

  # If +default_finders+ has been set and +key+ is not a +Fixnum+ then it
  # loops thru each +default_finders+ and returns the first matching result
  # of +find_by(finder => key)+ or +find_all(finder => key.first)+ if +key+
  # is an +Array+. If +key+ is already a +Hash+ or an +Array+ containing one
  # then it acts like an alias for +find_by+ or +find_all+ respectively. It
  # behaves exactly like its superclass +Array+ in all other cases.
  #
  #   # The initializer accepts optional +default_finders+
  #   users = QueryableArray.new(User.all, :username)
  #
  #   # The following all return the same user object
  #   users['example']
  #   users.find_by(username: 'example')
  #   users.find_by_username('example')
  #   users.find_all(username: 'example').first
  #   users.find { |user| user.username == 'example' }
  #   users[2] # assuming that's the index of the example user
  #
  #   pages = QueryableArray.new(Page.all, [:uri, :name])
  #
  #   pages['/']        # => #<Page @uri='/'>
  #   pages['Home']     # => #<Page @name='Home'>
  #   pages[/home/i]    # => #<Page @name='Home'>
  #   pages['missing']  # => nil
  #
  #   pages[uri: '/']                # => #<Page @uri='/' @name='Home'>
  #   pages[uri: '/', name: 'Home']  # => #<Page @uri='/' @name='Home'>
  #   pages[uri: '/', name: 'Typo']  # => nil
  #
  #   pages[[/procedures/i]]           # => [#<Page @uri='/procedures/facelift'>, #<Page @uri='/procedures/liposuction'>]
  #   pages[[uri: '/']]                # => [#<Page @uri='/' @name='Home'>]
  #   pages[[uri: '/', name: 'Typo']]  # => []
  def [](key)
    super
  rescue TypeError => error
    if default_finders.empty?
      raise error
    else
      finder, key = key.is_a?(Array) ? [:find_all, key.first] : [:find_by, key]
      if key.is_a?(Hash)
        send finder, key
      else
        detector, default = finder == :find_all ? [:empty?, []] : [:nil?, nil]
        default_finders.find do |attribute|
          match = send finder, attribute => key
          return match unless match.send detector
        end || default
      end
    end
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
  alias_method :find_all_by, :find_all

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

  # Determines if the +method+ passed to it can be parsed into a search hash
  # for +finder+.
  #
  #   finder? :find_by_name                      # => true
  #   finder? :find_by_first_name_and_last_name  # => true
  #   finder? :find_all_by_last_name             # => true
  #   finder? :find_all_by_last_name_and_city    # => true
  #   finder? :find_by_name_or_age               # => false
  #   finder? :find_first_by_name                # => false
  #   finder? :find_name                         # => false
  #   finder? :some_method                       # => false
  def finder?(method)
    method.to_s.match(/^(find(_all)?_by)_(.+)$/)
  end

  # If +method+ is a +finder?+ then it creates a search hash by zipping the
  # names of attributes parsed from +method+ as keys and +arguments+ as expected
  # values. The search hash is then passed to +find_all+ or +find_by+ depending
  # on what type of method was called.
  #
  # If +method+ is not a +finder?+ then +self[method]+ is returned. If it returns
  # +nil+ or raises +TypeError+ (no +default_finders+) then +super+ is returned.
  #
  #   users = QueryableArray.new User.all, :username
  #
  #   users.find_by_name 'bob'              # => #<User @name='bob'>
  #   users.find_by_name_and_age 'jim', 23  # => #<User @name='jim' @age=23>
  #   users.find_all_by_age 27              # => [#<User @age=27>, #<User @age=27>, ...]
  #
  #   users.bob                             # => #<User @name='bob'>
  #   users.missing                         # => NoMethodError
  #   QueryableArray.new.missing            # => NoMethodError
  def method_missing(method, *arguments)
    if query = finder?(method)
      search = Hash[query[3].split('_and_').zip(arguments)]
      send query[1], search
    else
      (self[method.to_s] rescue TypeError nil) || super
    end
  end

  # Determines if +method+ is a +finder?+ and delegates the call to its
  # superclass +Array+ if it's not.
  def respond_to_missing?(method, include_super)
    finder?(method) || super
  end
end