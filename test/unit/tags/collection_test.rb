require File.expand_path('../../test_helper', File.dirname(__FILE__))

class CollectionTagTest < ActiveSupport::TestCase
  
  module TestCollectionScope
    def self.included(base)
      base.scope :cms_collection, lambda{|*args| base.where(:slug => args.first) if args.first }
    end
  end
  Cms::Snippet.send(:include, TestCollectionScope)
  
  def test_initialize_tag
    assert tag = ComfortableMexicanSofa::Tag::Collection.initialize_tag(
      cms_pages(:default), '{{ cms:collection:snippet:cms/snippet }}'
    )
    assert_equal 'snippet',               tag.label
    assert_equal 'Cms::Snippet',          tag.collection_class
    assert_equal 'partials/cms/snippets', tag.collection_partial
    assert_equal 'label',                 tag.collection_title
    assert_equal 'id',                    tag.collection_identifier
    assert_equal [],                      tag.collection_params
  end
  
  def test_initialize_tag_detailed
    assert tag = ComfortableMexicanSofa::Tag::Collection.initialize_tag(
      cms_pages(:default), '{{ cms:collection:snippet:cms/snippet:path/to/partial:title:slug:param_a:param_b }}'
    )
    assert_equal 'snippet',         tag.label
    assert_equal 'Cms::Snippet',    tag.collection_class
    assert_equal 'path/to/partial', tag.collection_partial
    assert_equal 'title',           tag.collection_title
    assert_equal 'slug',            tag.collection_identifier
    assert_equal ['param_a', 'param_b'], tag.collection_params
  end
  
  def test_initialize_tag_failure
    [ 
      '{{cms:collection}}',
      '{{cms:collection:label}}',
      '{{cms:not_collection:label:class:partial}}',
      '{not_a_tag}'
    ].each do |tag_signature|
      assert_nil ComfortableMexicanSofa::Tag::Collection.initialize_tag(
        cms_pages(:default), tag_signature
      )
    end
  end
  
  def test_collection_objects
    assert tag = ComfortableMexicanSofa::Tag::Collection.initialize_tag(
      cms_pages(:default), '{{ cms:collection:snippet:cms/snippet }}'
    )
    assert snippets = tag.collection_objects
    assert_equal 1, snippets.count
    assert snippets.first.is_a?(Cms::Snippet)
  end
  
  def test_collection_objects_with_scope
    assert tag = ComfortableMexicanSofa::Tag::Collection.initialize_tag(
      cms_pages(:default), "{{ cms:collection:snippet:cms/snippet:path/to/partial:label:slug:#{cms_snippets(:default).slug} }}"
    )
    assert snippets = tag.collection_objects
    assert_equal 1, snippets.count
    assert snippets.first.is_a?(Cms::Snippet)
    
    assert tag = ComfortableMexicanSofa::Tag::Collection.initialize_tag(
      cms_pages(:default), "{{ cms:collection:snippet:cms/snippet:path/to/partial:label:slug:invalid }}"
    )
    assert snippets = tag.collection_objects
    assert_equal 0, snippets.count
  end
  
  def test_content_and_render
    assert tag = ComfortableMexicanSofa::Tag::Collection.initialize_tag(
      cms_pages(:default), '{{ cms:collection:snippet:cms/snippet }}'
    )
    assert tag.content.blank?
    
    snippet = cms_snippets(:default)
    tag.content = snippet.id
    assert_equal snippet.id, tag.block.content
    assert_equal snippet.id, tag.content
    assert_equal "<%= render :partial => 'partials/cms/snippets', :locals => {:model => 'Cms::Snippet', :identifier => '#{snippet.id}'} %>", tag.render
  end
  
  def test_content_and_render_detailed
    assert tag = ComfortableMexicanSofa::Tag::Collection.initialize_tag(
      cms_pages(:default), '{{ cms:collection:snippet:cms/snippet:path/to/partial:label:slug:param_a:param_b }}'
    )
    assert tag.content.blank?
    
    snippet = cms_snippets(:default)
    tag.content = snippet.slug
    assert_equal snippet.slug, tag.block.content
    assert_equal snippet.slug, tag.content
    assert_equal "<%= render :partial => 'path/to/partial', :locals => {:model => 'Cms::Snippet', :identifier => '#{snippet.slug}', :param_1 => 'param_a', :param_2 => 'param_b'} %>", tag.render
  end
  
  def test_content_and_render_with_no_content
    assert tag = ComfortableMexicanSofa::Tag::Collection.initialize_tag(
      cms_pages(:default), '{{ cms:collection:snippet:cms/snippet:path/to/partial }}'
    )
    assert tag.content.blank?
    assert_equal '', tag.render
  end
  
end