require File.expand_path('../test_helper', __FILE__)
require 'queryable_array'

describe QueryableArray do
  let(:page) { Struct.new(:uri, :name) }
  let(:pages) { (1..3).inject([]) { |pages, index| pages << page.new("page_#{index}", "PAGE_#{index}") } }
  let(:collection) { QueryableArray.new pages, [:uri, :name] }

  describe :[] do
    it 'should accept Fixnum arguments' do
      collection[0].must_equal pages[0]
      collection[99].must_be_nil
    end

    it 'should lookup objects by default_finders' do
      collection['page_1'].must_equal pages[0]
      collection['PAGE_1'].must_equal pages[0]
      collection['page_99'].must_be_nil
    end

    it 'should lookup objects by regex' do
      collection[/page_1/].must_equal pages[0]
    end

    it 'should lookup objects by hash' do
      collection[:uri => 'page_1'].must_equal pages[0]
      collection[:uri => 'page_1', :name => 'PAGE_1'].must_equal pages[0]
      collection[:uri => 'page_1', :name => 'INVALID'].must_equal nil
    end

    it 'should not accept shorthand searches if default_finders is nil' do
      proc { QueryableArray.new(pages)['page_1'] }.must_raise TypeError
    end

    it 'should accept an array to return all matches' do
      collection[['page_1']].must_equal [pages[0]]
      collection[[/page/]].must_equal pages
      collection[['missing']].must_equal []
      collection[[:uri => 'page_1']].must_equal [pages[0]]
      collection[[:uri => 'page_1', :name => 'PAGE_1']].must_equal [pages[0]]
      collection[[:uri => /page/]].must_equal pages
      collection[[:uri => 'page_1', :name => 'INVALID']].must_equal []
    end

    it 'should check all attributes before returning matches' do
      struct = Struct.new(:first_name, :last_name)
      collection = QueryableArray.new [struct.new('steve', 'hudson'), struct.new('hudson', 'jones')], [:first_name, :last_name]
      collection[['hudson']].must_equal collection
    end

    it 'should accept a proc' do
      collection[:name => proc { |name| $1.to_i == 2 if name =~ /.+?(\d+)$/ }].must_equal pages[1]
      collection[proc { |page| page.uri == 'page_1' }].must_equal pages[0]
    end

    it 'should accept callable objects' do
      callable = Class.new { def self.call(object); object.to_s == 'PAGE_1'; end }
      collection[:name => callable].must_equal pages[0]
      collection[callable].must_be_nil
      pages[0].instance_eval { def to_s; 'PAGE_1'; end }
      collection[callable].must_equal pages[0]
    end

    it 'should not throw NoMethodError if an attribute does not exist' do
      collection[:missing => 'test'].must_be_nil
      collection[[:missing => 'test']].must_equal []
    end
  end

  describe :find_by do
    it 'should only return the first match' do
      struct = Struct.new(:name, :age)
      collection = QueryableArray.new [struct.new('bob', 23), struct.new('steve', 23)]
      collection.find_by(:age => 23).must_equal collection[0]
    end
  end

  describe :find_all do
    it 'should return a QueryableArray instance' do
      collection.find_all { |page| page.uri == 'page_1' }.must_be_instance_of QueryableArray
    end

    it 'should lookup by search Hash' do
      collection.find_all(:uri => 'page_1').must_equal [pages[0]]
      collection.find_all(:uri => 'page_1', :name => 'PAGE_1').must_equal [pages[0]]
      collection.find_all(:uri => 'page_1', :name => 'PAGE_3').must_equal []
    end

    it 'should lookup by regex matches' do
      collection.find_all(:uri => /^page_\d$/).must_equal collection
      collection.find_all(:uri => /^page_1$/).must_equal [pages[0]]
    end

    it 'should be aliased as find_all_by' do
      collection.respond_to?(:find_all_by).must_equal true
      collection.find_all_by(:uri => 'page_1').must_equal collection.find_all(:uri => 'page_1')
    end

    it 'should return a QueryableArray with the same default_finders' do
      collection.find_all(:uri => 'page_1').default_finders.must_equal collection.default_finders
      collection.default_finders.wont_be_nil
    end
  end

  describe :finder? do
    it 'should check if a method matches a finder' do
      collection.finder?('find_by_name').wont_be_nil
      collection.finder?('find_all_by_name').wont_be_nil
      collection.finder?('find_by_name_and_uri').wont_be_nil
      collection.finder?('find_all_by_name_and_uri').wont_be_nil
      collection.finder?('find_by_nil?').wont_be_nil
      collection.finder?('find_by_name!').wont_be_nil
      collection.finder?('find_by').must_be_nil
    end

    describe 'a match' do
      let(:match) { collection.finder?('find_all_by_name_and_email_address!') }
      let(:singular) { collection.finder?('find_by_name') }
      let(:keys) { [:method_name, :prefix, :type, :attributes, :suffix] }

      it 'should return a Hash object' do
        match.must_be_instance_of Hash
      end

      it 'should return results in a specific order' do
        match.must_equal Hash[keys.zip %w[find_all_by_name_and_email_address! find_all_by all_by name_and_email_address !]]
        singular.must_equal Hash[keys.zip ['find_by_name', 'find_by', 'by', 'name', nil]]
      end
    end
  end

  describe :method_missing do
    it 'should pass finder methods to find_by' do
      pages = collection.find_all_by_name('PAGE_1')
      pages.size.must_equal 1
      pages[0].name.must_equal 'PAGE_1'
      collection.find_by_name('PAGE_1').must_equal pages[0]
    end

    it 'should allow searches by undefined methods' do
      collection.find_by_undefined_method('PAGE_1').must_be_nil
    end

    it 'should allow multiple search attributes' do
      collection.find_by_name_and_uri('PAGE_1', 'page_1').must_equal pages[0]
      collection.find_by_name_and_uri('PAGE_1', 'page_3').must_be_nil
    end

    it 'should allow default finder lookups by method name using regex' do
      collection.page_1.must_equal pages[0]
      collection.PAGE_1.must_equal pages[0]
      collection.pAgE_1.must_equal pages[0]
      proc { collection.page_99 }.must_raise NoMethodError
    end

    it 'should allow strict default finder lookups by method name using the raw value' do
      collection.page_1!.must_equal pages[0]
      collection.PAGE_1!.must_equal pages[0]
      proc { collection.pAgE_1! }.must_raise NoMethodError
    end

    it 'should pass non finder methods to super' do
      proc { collection.missing }.must_raise NoMethodError
    end

    it 'should return a boolean when looking up using a ?' do
      collection.page_1?.must_equal true
      collection.pAgE_1?.must_equal true
      collection.missing?.must_equal false
    end
  end

  describe :respond_to_missing? do
    it 'should check if the method is a finder' do
      collection.respond_to?(:find_by_name).must_equal true
      collection.respond_to?(:find_all_by_name).must_equal true
      collection.respond_to?(:find_stuff).must_equal false
      collection.respond_to?(:invalid).must_equal false
    end

    it 'should check if the method can be handled by DotNotation' do
      collection.respond_to?(:page_1).must_equal true
      collection.respond_to?(:PAGE_1).must_equal true
      collection.respond_to?(:pAgE_1).must_equal true
      collection.respond_to?(:page_1?).must_equal true
      collection.respond_to?(:missing?).must_equal true
      collection.respond_to?(:page_1!).must_equal true
      collection.respond_to?(:pAgE_1!).must_equal false
      collection.respond_to?(:missing).must_equal false
    end
  end
end