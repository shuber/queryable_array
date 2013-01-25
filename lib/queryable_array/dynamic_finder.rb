class QueryableArray < Array
  module DynamicFinder
    def self.included(base)
      base.send :alias_method, :find_all_by, :find_all
    end

    # Determines if the +method_name+ passed to it can be parsed into a search hash
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
    def finder?(method_name)
      if match = method_name.to_s.match(/^(find_(by|all_by))_(.+?)([\?\!])?$/i)
        keys = [:method_name, :prefix, :type, :attributes, :suffix]
        Hash[keys.zip match.to_a]
      end
    end

    # If +method_name+ is a +finder?+ then it creates a search hash by zipping the
    # names of attributes parsed from +method_name+ as keys and +arguments+ as expected
    # values. The search hash is then passed to +find_all+ or +find_by+ depending
    # on what type of method was called.
    #
    #   users = QueryableArray.new User.all, :username
    #
    #   users.find_by_name 'bob'              # => #<User @name='bob'>
    #   users.find_by_name_and_age 'jim', 23  # => #<User @name='jim' @age=23>
    #   users.find_all_by_age 27              # => [#<User @age=27>, #<User @age=27>, ...]
    def method_missing(method_name, *arguments)
      if query = finder?(method_name)
        search = Hash[query[:attributes].split('_and_').zip(arguments)]
        send "find_#{query[:type].downcase}", search
      else
        super
      end
    end

    # Determines if +method_name+ is a +finder?+ and delegates the call to its
    # superclass +Array+ if it's not.
    def respond_to_missing?(method_name, include_super)
      !!finder?(method_name) || super
    end
  end
end