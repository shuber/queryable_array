class QueryableArray < Array
  module Shorthand
    # If +key+ is a +Hash+, +Proc+, or an +Array+ containing a +Hash+ or +Proc+
    # then it acts like an alias for +find_by+ or +find_all+ respectively. It
    # delegates the call to +super+ in all other cases.
    #
    #   pages = QueryableArray.new Page.all
    #
    #   pages[uri: '/']                # => #<Page @uri='/' @name='Home'>
    #   pages[uri: '/', name: 'Home']  # => #<Page @uri='/' @name='Home'>
    #   pages[uri: '/', name: 'Typo']  # => nil
    #
    #   pages[[uri: '/']]                # => [#<Page @uri='/' @name='Home'>]
    #   pages[[uri: '/', name: 'Typo']]  # => []
    #
    #   pages[uri: proc { |uri| uri.count('/') > 1 }]  # => #<Page @uri='/users/bob' @name='Bob'>
    def [](key)
      # Try to handle numeric indexes, ranges, and anything else that is
      # natively supported by +Array+ first
      super
    rescue TypeError => error
      method, key = key.is_a?(Array) ? [:find_all, key.first] : [:find_by, key]
      key.is_a?(Hash) ? send(method, key) : raise(error)
    end
  end
end