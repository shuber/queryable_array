require 'respond_to_missing'
require 'queryable_array/dot_notation'
require 'queryable_array/dynamic_finder'
require 'queryable_array/queryable'
require 'queryable_array/shorthand'

# A +QueryableArray+ inherits from +Array+ and is intended to store a group of
# objects which share the same attributes allowing them to be searched. It
# overrides +[]+, +find_all+ and +method_missing+ to provide a simplified DSL
# for looking up objects by querying their attributes.
class QueryableArray < Array
  include Queryable
  include Shorthand
  include DotNotation
  include DynamicFinder
end