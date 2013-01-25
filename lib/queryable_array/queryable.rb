class QueryableArray < Array
  module Queryable
    # Returns a dup'd +Queryable+ replaced with objects matching the +search+
    # criteria. When a +block+ is specified, it behaves exactly like
    # +Enumerable#find_all+. Otherwise the +search+ hash is converted into
    # a +finder+ proc and passed as the block argument to +Enumerable#find_all+.
    #
    #   users.find_all(age: 30)                  # => [#<User @age=30>, #<User @age=30>, ...]
    #   users.find_all(name: 'missing')          # => []
    #   users.find_all { |user| user.age < 30 }  # => [#<User @age=22>, #<User @age=26>, ...]
    def find_all(search = {}, &block)
      block = finder search unless block_given?
      dup.replace super(&block)
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
    # object's searched attributes match their expected values. It can be used as
    # the block arguments for +find+, +find_by+ and +find_all+.
    #
    # Values are compared with expected values using <tt>==</tt> or <tt>===</tt>.
    # If the expected value is a +Proc+ or anything that responds to +call+ then
    # it is evaluated with the +value+ as an argument and checks for a response
    # other than +nil+ or +false+.
    #
    #   query = finder(name: 'bob')    # => proc { |user| user.name == 'bob' }
    #   query User.new(name: 'steve')  # => false
    #   query User.new(name: 'bob')    # => true
    #
    #   users.find(&query)             # => #<User @name='bob'>
    def finder(search)
      Proc.new do |object|
        search.all? do |attribute, expected|
          value = object.send attribute if object.respond_to?(attribute)
          expected == value || expected === value || (expected.respond_to?(:call) && expected.call(value))
        end
      end
    end
  end
end