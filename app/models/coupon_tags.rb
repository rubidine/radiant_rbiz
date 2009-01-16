module CouponTags
  include Radiant::Taggable

  desc 'Exapnd a coupon set by cart:coupons:each'
  tag 'cart:coupons' do |tag|
    tag.expand
  end

  desc 'Loop over each coupon in the cart'
  tag 'cart:coupons:each' do |tag|
    rv = ''
    tag.locals.cart.coupons.each do |c|
      tag.locals.coupon = c
      rv << tag.expand
    end
    rv
  end

  desc 'Show coupon code'
  tag 'cart:coupons:code' do |tag|
    tag.locals.coupon.code
  end

  desc 'Show coupon discount'
  tag 'cart:coupons:discount' do |tag|
    "%.2f" % tag.locals.coupon.discount_for(tag.locals.cart)
  end
end
