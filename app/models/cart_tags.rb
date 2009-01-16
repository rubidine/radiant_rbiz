module CartTags
  include Radiant::Taggable

  desc 'Load the cart.  Used in cart controller actions and customer:receipts.'
  tag 'cart' do |tag|
    unless tag.locals.cart
      '&lt;r:cart&gt; is not available on this page.'
    else
      tag.expand
    end
  end

  desc 'Expand if cart is empty'
  tag 'cart:if_empty' do |tag|
    tag.expand if tag.locals.cart.line_items.empty?
  end

  desc 'Expand unless cart is empty'
  tag 'cart:unless_empty' do |tag|
    tag.expand unless tag.locals.cart.line_items.empty?
  end

  desc 'Expand if freight shipping is required'
  tag 'cart:if_freight' do |tag|
    tag.expand if tag.locals.cart.freight_shipping?
  end

  desc 'Expand unless freight shipping is required'
  tag 'cart:unless_freight' do |tag|
    tag.expand unless tag.locals.cart.freight_shipping?
  end

  desc 'Expand if there was an error calculating shipping'
  tag 'cart:if_shipping_error' do |tag|
    tag.expand if tag.locals.cart.shipping_error?
  end

  desc 'Expand unless there was an error calculating shipping'
  tag 'cart:unless_shipping_error' do |tag|
    tag.expand unless tag.locals.cart.shipping_error?
  end

  desc 'Show the error message from the cart'
  tag 'cart:error_message' do |tag|
    tag.locals.cart.error_message
  end

  ['comments', 'id', 'status_message'].each do |tn|
    desc "Show the #{tn} from the cart"
    tag "cart:#{tn}" do |tag|
      tag.locals.cart.send(tn)
    end
  end

  ['tax', 'shipping', 'total'].each do |tn|
    desc "#{tn.capitalize} price of the current cart"
    tag "cart:#{tn}" do |tag|
      p = tag.locals.cart.send("#{tn}_price")
      if p.nil?
        'Not computed (no address?)'
      else
        '%.2f' % p
      end
    end
  end

  desc 'Grand total of the entire purchase'
  tag 'cart:grand_total' do |tag|
    "%.2f" % tag.locals.cart.grand_total
  end

  ['updated_at', 'created_at', 'fulfilled_at', 'sold_at'].each do |ts|
    desc "Show the timestamp from when cart #{ts}"
    tag "cart:#{ts}" do |tag|
      sarg = tag.attr['format'] || "%d %b %Y %H:%M"
      v = tag.locals.cart.send(ts)
      v ? v.strftime(sarg) : ''
    end
  end

  desc 'Expand if a cart can have a coupon added to it'
  tag 'cart:if_can_add_coupon' do |tag|
    unless CartConfig.get(:coupons, :disabled) \
    or (CartConfig.get(:coupons, :allow_only_one) and !@cart.coupons.empty?)
      tag.expand
    end
  end

  desc 'expand if shipping is taxable'
  tag 'cart:if_tax_shipping' do |tag|
    tag.expand if tag.locals.cart.taxable?
  end

  desc 'show the tax rate'
  tag 'cart:tax_rate' do |tag|
    tag.locals.cart.tax_rate
  end


  desc 'show the tax rate'
  tag 'cart:tax_rate' do |tag|
    tag.locals.cart.tax_rate
  end

end
