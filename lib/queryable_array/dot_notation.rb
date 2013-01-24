require 'queryable_array/default_finder'

class QueryableArray < Array
  module DotNotation
    def self.included(base)
      base.send :include, DefaultFinder
    end

    # If +method_name+ does not have a <tt>!</tt> or <tt>?</tt> suffix then +self[/#{method_name}/i]+
    # is returned. If it returns +nil+ or raises +TypeError+ (no +default_finders+) then +super+ is returned.
    #
    # If +method_name+ ends in a <tt>!</tt> then +self[method_name]+ (without the <tt>!</tt>) is returned. If +method_name+
    # ends with a <tt>?</tt> then a boolean is returned determining whether or not a match was found.
    #
    #   users = QueryableArray.new User.all, :username
    #
    #   users.bob                             # => #<User @name='bob'>
    #   users.BOB                             # => #<User @name='bob'>
    #   users.missing                         # => NoMethodError
    #   QueryableArray.new.missing            # => NoMethodError
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

    def respond_to_missing?(method_name, include_super)
      method_name.to_s =~ /\?$/ || super || send(method_name)
    rescue NoMethodError
      false
    end
  end
end