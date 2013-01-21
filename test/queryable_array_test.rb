$: << File.expand_path('../../lib', __FILE__)
require 'queryable_array'
require 'minitest/spec'
require 'minitest/autorun'

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
      collection[uri: 'page_1'].must_equal pages[0]
      collection[uri: 'page_1', name: 'PAGE_1'].must_equal pages[0]
      collection[uri: 'page_1', name: 'INVALID'].must_equal nil
    end

    it 'should not accept strings if default_finders is nil' do
      proc { QueryableArray.new(pages)['page_1'] }.must_raise TypeError
    end

    it 'should accept an array to return all matches' do
      collection[['page_1']].must_equal [pages[0]]
      collection[[/page/]].must_equal pages
      collection[['missing']].must_equal []
      collection[[uri: 'page_1']].must_equal [pages[0]]
      collection[[uri: 'page_1', name: 'PAGE_1']].must_equal [pages[0]]
      collection[[uri: /page/]].must_equal pages
      collection[[uri: 'page_1', name: 'INVALID']].must_equal []
    end
  end

  describe :find_by do
    it 'should only return the first match' do
      struct = Struct.new(:name, :age)
      collection = QueryableArray.new [struct.new('bob', 23), struct.new('steve', 23)]
      collection.find_by(age: 23).must_equal collection[0]
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

    it 'should return a MatchData object' do
      collection.finder?('find_by_name').must_be_instance_of MatchData
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

    it 'should allow default finder lookups by method name' do
      collection.page_1.must_equal pages[0]
      collection.PAGE_1.must_equal pages[0]
      proc { collection.page_99 }.must_raise NoMethodError
    end

    it 'should pass non finder methods to super' do
      proc { collection.missing }.must_raise NoMethodError
    end
  end
end