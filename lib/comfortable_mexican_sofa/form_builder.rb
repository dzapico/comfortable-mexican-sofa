class ComfortableMexicanSofa::FormBuilder < ActionView::Helpers::FormBuilder
  
  helpers = field_helpers -
    %w(hidden_field fields_for) +
    %w(select)
    
  helpers.each do |name|
    class_eval %Q^
      def #{name}(field, *args)
        options = args.extract_options!
        args << options
        return super if options.delete(:disable_builder)
        default_field('#{name}', field, options){ super }
      end
    ^
  end
  
  def default_field(type, field, options = {}, &block)
    errors = if object.respond_to?(:errors) && object.errors[field].present?
      "<div class='errors'>#{[object.errors[field]].flatten.first}</div>"
    end
    if desc = options.delete(:desc)
      desc = "<div class='desc'>#{desc}</div>"
    end
    %(
      <div class='form_element #{type}_element #{'errors' if errors}'>
        <div class='label'>#{label_for(field, options)}</div>
        <div class='value'>#{yield}</div>
        #{desc}
        #{errors}
      </div>
    ).html_safe
  end
  
  def simple_field(label = nil, content = nil, options = {}, &block)
    content ||= @template.capture(&block) if block_given?
    %(
      <div class='form_element #{options.delete(:class)}'>
        <div class='label'>#{label}</div>
        <div class='value'>#{content}</div>
      </div>
    ).html_safe
  end
  
  def label_for(field, options={})
    label = options.delete(:label) || object.class.human_attribute_name(field).titleize
    for_value = options[:id] || "#{object_name}_#{field}"
    %Q{<label for="#{for_value}">#{label}</label>}.html_safe
  end
  
  def submit(value, options = {}, &block)
    return super if options.delete(:disable_builder)
    extra_content = @template.capture(&block) if block_given?
    simple_field(nil, "#{super(value, options)} #{extra_content}", :class => 'submit_element')
  end
  
  # -- Tag Field Fields -----------------------------------------------------
  def default_tag_field(tag, options = {})
    label     = options[:label] || tag.label.to_s.titleize
    css_class = options[:css_class] || tag.class.to_s.demodulize.underscore
    
    field_css_class = case tag
    when ComfortableMexicanSofa::Tag::PageDateTime, ComfortableMexicanSofa::Tag::FieldDateTime
      'datetime'
    when ComfortableMexicanSofa::Tag::PageText, ComfortableMexicanSofa::Tag::FieldText
      'code'
    when ComfortableMexicanSofa::Tag::PageRichText
      'rich_text'
    end
    
    options[:content_field_method] ||= :text_field_tag
    field = 
      options[:field] || 
      @template.send(
        options[:content_field_method],
        'page[blocks_attributes][][content]',
        tag.content,
        :id     => nil, 
        :class  => field_css_class
      )
    content = "#{field} #{@template.hidden_field_tag('page[blocks_attributes][][label]', tag.label, :id => nil)}"
    simple_field(label, content, :class => css_class)
  end
  
  def field_date_time(tag)
    default_tag_field(tag)
  end
  
  def field_integer(tag)
    default_tag_field(tag, :content_field_method => :number_field_tag)
  end
  
  def field_string(tag)
    default_tag_field(tag)
  end
  
  def field_text(tag)
    default_tag_field(tag, :content_field_method => :text_area_tag)
  end
  
  def page_date_time(tag)
    default_tag_field(tag)
  end
  
  def page_integer(tag)
    default_tag_field(tag, :content_field_method => :number_field_tag)
  end
  
  def page_string(tag)
    default_tag_field(tag)
  end
  
  def page_text(tag)
    default_tag_field(tag, :content_field_method => :text_area_tag)
  end
  
  def page_rich_text(tag)
    default_tag_field(tag, :content_field_method => :text_area_tag)
  end
  
  def collection(tag)
    options = [["---- Select #{tag.collection_class.titleize} ----", nil]] + 
      tag.collection_objects.collect do |m| 
        [m.send(tag.collection_title), m.send(tag.collection_identifier)]
      end
      
    content = @template.select_tag(
      'page[blocks_attributes][][content]',
      @template.options_for_select(options, :selected => tag.content),
      :id => nil
    )
    content << @template.hidden_field_tag('page[blocks_attributes][][label]', tag.label, :id => nil)
    simple_field(tag.label, content, :class => tag.class.to_s.demodulize.underscore )
  end
  
end
