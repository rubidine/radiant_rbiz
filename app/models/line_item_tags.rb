module LineItemTags
  include Radiant::Taggable

  tag 'cart:line_item' do |tag|
    tag.expand
  end

  desc %{
    Iterate over each line item
  }
  tag 'cart:line_item:each' do |tag|
    op = ''
    tag.locals.cart.line_items.each do |li|
      tag.locals.line_item = li
      op << tag.expand
    end
    op
  end

  desc %{
    Expand if this is a product-based
  }
  tag 'cart:line_item:if_product' do |tag|
    if tag.locals.line_item.product
      tag.expand
    end
  end

  desc %{
    Expand unless this is a product-based
  }
  tag 'cart:line_item:unless_product' do |tag|
    unless tag.locals.line_item.product
      tag.expand
    end
  end

  desc %{
    Expand if this line item has options specifications by customer input
  }
  tag 'cart:line_item:if_option_specifications' do |tag|
    unless tag.locals.line_item.option_sepecifications.empty?
      tag.expand
    end
  end

  ['individual_price', 'price', 'individual_weight', 'weight'].each do |t|
    desc %{
      Show the #{t} for the line item
    }
    tag "cart:line_item:#{t}" do |tag|
      "%.2f" % tag.locals.line_item.send(t)
    end
  end

  ['quantity', 'name', 'full_sku', 'specifications', 'id'].each do |t|
    desc %{
      Show the #{t} for the line item
    }
    tag "cart:line_item:#{t}" do |tag|
      tag.locals.line_item.send(t)
    end
  end

  desc %{
    Expand this tag if the line item is custom
  }
  tag "cart:line_item:if_custom" do |tag|
    tag.expand if tag.locals.line_item.custom?
  end

  desc %{
    Expand this tag unless the line item is custom
  }
  tag "cart:line_item:unless_custom" do |tag|
    tag.expand unless tag.locals.line_item.custom?
  end

  desc %{
    Product Of the line item.
    Will make the product available with r:product tags.
  }
  tag 'cart:line_item:product_id' do |tag|
    tag.locals.product = tag.locals.line_item.product
    tag.expand
  end

end
