module ShippingMethodTags
  include Radiant::Taggable

  tag 'shipping_method' do |tag|
    tag.expand
  end

  desc 'Loop over each shipping method'
  tag 'shipping_method:each' do |tag|
    if tag.locals.cart and tag.locals.cart.shipping_responses
      rv = ''
      tag.locals.cart.shipping_responses.each do |sm|
        tag.locals.shipping_method = sm
        rv << tag.expand
      end
      rv
    else
      'No shipping methods are available'
    end
  end

  desc 'Exapnd if there is more than one shipping method'
  tag 'shipping_method:if_multiple' do |tag|
    tag.expand if tag.locals.cart and tag.locals.cart.shipping_responses.length > 1
  end

  desc 'Exapnd unless there is more than one shipping method'
  tag 'shipping_method:unless_multiple' do |tag|
    tag.expand if tag.locals.cart and tag.locals.cart.shipping_responses.length <= 1
  end

  ['plugin_name', 'subtype', 'message', 'id'].each do |name|
    desc "Show #{name} for shipping method"
    tag "shipping_method:#{name}" do |tag|
      tag.locals.shipping_method.send(name)
    end
  end

  desc 'show cost of shipping method'
  tag 'shipping_method:cost' do |tag|
    "%.2f" % tag.locals.shipping_method.cost
  end

  desc 'show the human readable shipping type'
  tag 'shipping_method:human_name' do |tag|
    m = tag.locals.shipping_method
    v = m.subtype || m.plugin_name
    v.to_s.humanize
  end
end
