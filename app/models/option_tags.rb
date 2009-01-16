module OptionTags
  include Radiant::Taggable

  tag 'product:options' do |tag|
    tag.expand
  end

  desc %{
    Run for each option available on a tag.
    You can also specify a set to limit with set="my_set_name".
  }
  tag 'product:options:each' do |tag|
    set = tag.attr['set']
    if set and set = OptionSet.find_by_name(set)
      options = tag.locals.product.options.find_by_option_set_id(set.id)
    end
    options ||= tag.locals.product.option_sets.collect{|x| x.options}.flatten
    rv = ''
    options.each do |opt|
      tag.locals.option = opt
      rv << tag.expand
    end
    rv
  end

  tag 'option' do |tag|
    tag.expand
  end

  desc %{
    Option Set Name
  }
  tag 'option:set_name' do |tag|
    tag.locals.option.option_set.name
  end

  desc %{
    Option Name
  }
  tag 'option:name' do |tag|
    tag.locals.option.name
  end

  desc %{
    Price Adjustment
  }
  tag 'option:price_adjustment' do |tag|
    "%.2f" % tag.locals.option.price_adjustment
  end

  desc %{
    If extension sku
  }
  tag 'option:if_sku_extension' do |tag|
    if tag.locals.option.sku_extension
      tag.expand
    else
      ''
    end
  end

  desc %{
    Unless extension sku
  }
  tag 'option:unless_sku_extension' do |tag|
    unless tag.locals.option.sku_extension
      tag.expand
    else
      ''
    end
  end

  desc %{
    Sku Extension
  }
  tag 'option:sku_extension' do |tag|
    tag.locals.option.sku_extension
  end

  desc %{
    short description
  }
  tag 'option:short_description' do |tag|
    tag.locals.option.short_description
  end
end
