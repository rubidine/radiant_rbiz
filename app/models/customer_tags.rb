module CustomerTags
  include Radiant::Taggable

  desc 'Load the customer from the current cart (only in cart controller)'
  tag 'customer' do |tag|
    if tag.locals.cart
      tag.locals.customer = tag.locals.cart.customer
      tag.expand
    else
      'Cart is not available on this page for customer tag'
    end
    # no more code here, return from above
  end

  desc 'Customer email'
  tag 'customer:email' do |tag|
    tag.locals.customer.email
  end

  desc 'Loop over customers receipts: access receipts with &lt;cart&gt; tags.'
  tag 'customer:each_receipt' do |tag|
    rv = ''
    tag.locals.customer.carts.find(
      :all,
      :conditions => ['status IN (3,6,7)'],
      :order => 'updated_at desc'
    ).each do |c|
      tag.locals.cart = c
      rv << tag.expand
    end
  end

end
