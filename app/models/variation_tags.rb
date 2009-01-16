module VariationTags
  include Radiant::Taggable

  desc %{
    -
  }
  tag 'product:if_variations' do |tag|
    unless tag.locals.product.variations.empty?
      tag.expand
    end
  end
 
  desc %{
    -
  }
  tag 'product:unless_variations' do |tag|
    if tag.locals.product.variations.empty?
      tag.expand
    end
  end

  tag 'product:variation' do |tag|
    tag.expand
  end

  desc %{
    For each available variation 
  }
  tag 'product:variation:each' do |tag|
    rv = ''
    tag.locals.product.variations.each do |var|
      tag.locals.variation = var
      rv << tag.expand
    end
    rv
  end

  desc %{
    Expand if this line item has variations 
  }
  tag 'cart:line_item:if_variations' do |tag|
    if tag.locals.line_item.variation
      tag.expand
    end
  end

  desc %{
    -
  }
  tag 'cart:line_item:variation' do |tag|
    tag.locals.variation = tag.locals.line_item.variation
    tag.expand
  end

  desc %{
    -
  }
  tag 'variation:each_option' do |tag|
    rv = ''
    tag.locals.variation.options.each do |opt|
      tag.locals.option = opt
      rv << tag.expand
    end
    rv
  end

  desc %{
    -
  }
  tag 'variation:id' do |tag|
    tag.locals.variation.id
  end

  desc %{
    -
  }
  tag 'variation:quantity' do |tag|
    tag.locals.variation.quantity.to_i.to_s
  end

  desc %{
    -
  }
  tag 'variation:real_price' do |tag|
    "%.2f" % (tag.locals.variation.product.price + tag.locals.variation.options.inject(0.0){|m,x| m + (x.price_adjustment || 0)})
  end

end
