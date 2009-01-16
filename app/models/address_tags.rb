module AddressTags
  include Radiant::Taggable
  include CartHelper

  desc 'Loop over each address a customer has for use in &lt;r:address&gt;'
  tag 'customer:each_address' do |tag|
    unless tag.locals.customer 
      return "Missing customer when calling tag customer:each_address"
    end
    rv = ''
    tag.locals.customer.addresses.each do |addr|
      tag.locals.address = addr
      rv << tag.expand
    end
    rv
  end

  desc 'Expand an address set into tag.locals by ' +
       'customer:each_address or cart:{shipping,billing}_address'
  tag 'address' do |tag|
    tag.expand
  end

  desc 'Name on address label'
  tag 'address:name' do |tag|
    tag.locals.address.display_name
  end

  %w{ street city state zip phone id }.each do |field|
    desc "Customer Address #{field}"
    tag "address:#{field}" do |tag|
      tag.locals.address.send(field)
    end
  end

  ['billing_address', 'shipping_address'].each do |addr|
    desc "load the #{addr} to be used in an &lt;r:address&gt; block"
    tag "cart:#{addr}" do |tag|
      tag.locals.address = tag.locals.cart.send(addr)
      tag.expand
    end
  end
  
  desc 'State drop-down'
  tag "address:state_dropdown" do |tag|
    state_select("address", "state")
  end
end
