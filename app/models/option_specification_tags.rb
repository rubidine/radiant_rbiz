module OptionSpecificationTags
  include Radiant::Taggable

  tag 'cart:line_item:option_specification' do |tag|
    tag.expand
  end

  desc %{
    Each option selection (sorted by option name)
  }
  tag 'cart:line_item:option_specification:each' do |tag|
    op = ''
    tag.locals.line_item.option_specifications.sort_by{|x| x.option.name}.each do |y|
      tag.locals.option_specification = y
      op << tag.expand
    end
  end

  desc %{
    Option Name
  }
  tag 'cart:line_item:option_specification:option_name' do |tag|
    tag.locals.option_specification.option.name
  end

  desc %{
    Customer Input
  }
  tag 'cart:line_item:option_specification:value' do |tag|
    tag.locals.option_specification.option_text
  end
end
