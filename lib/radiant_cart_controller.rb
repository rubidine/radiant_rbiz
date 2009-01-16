module RadiantCartController

  def self.included kls
    kls.send :before_filter, :assign_cart_to_page
#    kls.send :before_filter,
#             :assign_shipping_methods_to_page,
#             :only => [:finalize, :finalize_post]
  end

  private
  def assign_cart_to_page
    if @cart
      @radiant_page_assignments ||= []
      @radiant_page_assignments << :cart
    end
  end

#  def assign_shipping_methods_to_page
#    @radiant_page_assignments ||= []
#    @radiant_page_assignments << :shipping_methods
#  end
end 
