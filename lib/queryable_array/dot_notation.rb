require 'queryable_array/default_finder'

class QueryableArray < Array
  # Allows objects to be searched using dot notation thru +method_missing+
  # which behaves like an alias to <tt>QueryableArray::DefaultFinder#[]</tt>
  module DotNotation
    def self.included(base)
      base.send :include, DefaultFinder
    end

    # If +method_name+ does not have a <tt>!</tt> or <tt>?</tt> suffix then <tt>self[/#{method_name}/i]</tt>
    # is returned. If it returns +nil+ or raises +TypeError+ (no +default_finders+) then +super+ is returned.
    #
    # If +method_name+ ends in a <tt>!</tt> then <tt>self[method_name]</tt> (without the <tt>!</tt>) is returned. If +method_name+
    # ends with a <tt>?</tt> then a boolean is returned determining whether or not a match was found.
    #
    #   users = QueryableArray.new User.all, :username
    #
    #   users.bob                   # => #<User @username='bob'>
    #   users.BOB                   # => #<User @username='bob'>
    #   users.missing               # => NoMethodError
    #   QueryableArray.new.missing  # => NoMethodError
    #
    #   users.bob!  # => #<User @username='bob'>
    #   users.BOB!  # => NoMethodError
    #
    #   users.bob?      # => true
    #   users.BOB?      # => true
    #   users.missing?  # => false
    def method_missing(method_name, *arguments)
      if method_name.to_s =~ /^(.+?)([\!\?])?$/
        search = $2 == '!' ? $1 : /#{$1}/i
        value = begin
          self[search]
        rescue TypeError
          nil
        end
        $2 == '?' ? !!value : (value || super)
      end
    end

    # Checks if +method_name+ can be handled by +method_missing+ and
    # and delegates the call to +super+ otherwise.
    def respond_to_missing?(method_name, include_super)
      !!(method_name.to_s =~ /\?$/ || super || send(method_name))
    rescue NoMethodError
      false
    end
  end
end