module RadiantOfficeController
  def self.included kls
    # When a product is edited
    kls.send :around_filter,
             :radiant_update_product,
             :only => [
               :product,
               :duplicate
             ]

    # When a tag is edited
    kls.send :around_filter,
             :radiant_update_tag,
             :only => :aj_tag_edit

    # When specific aspects of a product are edited
    kls.send :after_filter,
             :radiant_flush_product,
             :only => [
                        :add_image,
                        :aj_activate_product,
                        :aj_update_description,
                        :aj_image_reorder,
                        :aj_image_delete,
                        :aj_create_option_set,
                        :aj_create_option,
                        :aj_delete_option_set,
                        :aj_delete_option,
                        :aj_create_bulk_price,
                        :aj_delete_bulk_price
                      ]

    # After import, rebuild the entire site
    kls.send :after_filter,
             :nuke_radiant_cache,
             :only => :finalize_import

    # Create new product
    kls.send :after_filter,
             :radiant_create_product,
             :only => :aj_new_product

    # Changes to a product that invalidates tags / tagsets
    kls.send :after_filter,
             :radiant_update_product_tree,
             :only => [
                        :aj_feature_product,
                        :aj_add_tag,
                        :aj_create_tag,
                        :aj_remove_tag
                      ]

    # Delete several producs
    kls.send :after_filter,
             :radiant_delete_products,
             :only => :delete_products

    # Change a tag page
    kls.send :after_filter,
             :radiant_flush_tag,
             :only => [
               :aj_delete_tag,
               :aj_add_tag_to_set
             ]

    # Delete a tagset
    kls.send :after_filter,
             :radiant_delete_tagset,
             :only => :aj_delete_tag_set

    # Create a tagset 
    kls.send :after_filter,
             :radiant_create_tagset,
             :only => :aj_new_tag_set
  end

  private
  def flush_radiant_page path
    # SOMETHING like the following would work well with virtual domains
    # and possibly other virtual page types that want to store data elsewhere
#    pg = Page.find_by_parent_id(nil)
#    return unless pg
#    pg.request = request
#    pg2 = pg.find_by_url(path, false)
#    if pg2 and !pg2.is_a?(FileNotFoundPage)
#      ResponseCache.instance.expire_page(pg2)
#    end

    # But this is reality
    ResponseCache.instance.expire_response(path)
  end

  def nuke_radiant_cache
    ResponseCache.instance.clear
  end

  def build_radiant_page path
    # TODO if we are configured for static mode, create the page
  end

  def radiant_update_product
    return unless request.post?
    if @radiant_old_product_slug
      flush_radiant_page("/products/#{@radiant_old_product_slug}")
      build_radiant_page("/products/#{@product.slug}")
    else
      @radiant_old_product_slug = (p = Product.find(params[:id])) ? p.slug : nil
    end
  end

  def radiant_update_tag
    return unless request.post?
    if @radiant_old_tag_slug
      flush_radiant_page("/tags/#{@radiant_old_tag_slug}")
      build_radiant_page("/tags/#{@tag.slug}")
    else
      @radiant_old_tag_slug = (p = Tag.find(params[:id])) ? p.slug : nil
    end
  end

  def radiant_flush_product
    radiant_flush_product_callback @product
  end

  def radiant_create_product
    build_radiant_page("/products/#{@product.slug}")
  end

  def radiant_update_product_tree
    radiant_update_product_tree_callback @product
  end

  def radiant_delete_products
    @products.each do |p|
      radiant_update_product_tree_callback product
    end
  end

  def radiant_delete_tagset
    flush_radiant_page("/tags/#{@tag.slug}")
  end

  def radiant_flush_tag
    radiant_flush_tag_callback @tag
  end

  def radiant_create_tagset
    build_radiant_page("/tags/#{@tagset.slug}")
  end

  def radiant_flush_product_callback product
    flush_radiant_page("/products/#{product.slug}")
    build_radiant_page("/products/#{product.slug}")
  end

  def radiant_flush_tag_callback tag
    flush_radiant_page("/tags/#{tag.tag_set.slug}/#{tag.slug}")
    build_radiant_page("/tags/#{tag.tag_set.slug}/#{tag.slug}")
  end

  def radiant_update_product_tree_callback product
    radiant_flush_product_callback product
    product.tags.each do |tag|
      radiant_flush_tag_callback tag
    end
    product.tags.collect{|x| x.tagset}.uniq.each do |ts|
      flush_radiant_page("/tags/#{ts.slug}")
      build_radiant_page("/tags/#{ts.slug}")
    end
  end
end
