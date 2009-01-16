module ProductTags 
  include Radiant::Taggable
  include RadiantWillPaginate

  # Start with the product
  desc %{
    This tag allows you to access a product's information.  It is a container
    for other tags like name, slug, image, etc.  Find the product by
    id or slug.
    
    <pre><code><r:product id="1"><r:name/></r:product></code></pre>
    <pre><code><r:product slug="my_product"><r:name/></r:product></code></pre>
  }
  tag "product" do |tag|
    if tag.attr['slug']
      tag.locals.product = Product.find_by_slug(tag.attr['slug'])
    elsif tag.attr['id']
      tag.locals.product = Product.find(tag.attr['id'])
    end
    tag.expand
  end

  # itterate over all products
  desc %{
    Cycles through each product.
    
    *Usage:*
    <pre><code><r:product:each [offset="number"] [limit="number"] [by="attribute"] [order="asc|desc"]>
     ...
     </r:product:each>
    </code></pre>
  }
  tag "product:each" do |tag|

    atr = tag.locals.product_attr

    if tag.attr['by_page']
      products = tag.locals.tag_products
    else
      opts = { :conditions => {} }

      if tag.attr['by']
        opts[:order] = tag.attr['by']
      else
        opts[:order] = "id"
      end
      
      if tag.attr['order']
        opts[:order] += " #{tag.attr['order']}"
      end

      if tag.attr['featured']
        opts[:conditions][:featured] = true.first <<  ' AND featured = ?'
      end

      if tag.attr['limit']
        opts[:limit] = tag.attr['limit']
      end

      if tag.attr['offset']
        opts[:offset] = tag.attr['offset']
      end

      paginate = nil
      if tag.attr['paginate']
        paginate = tag.attr['paginate'].to_i
      end

      products = nil
      if paginate
        opts[:per_page] = paginate
        opts[:page] = get_page_by_url_or_param(tag)
        products = Product.available.paginate(opts)

        # register as global so paginate finds it
        # the paginate call will be outside of this tag
        tag.globals.products = products
      else
        products = Product.available.find(:all, opts)  
      end
    end


    op = ''
    products.each do |p|
      tag.locals.product = p
      op << tag.expand
    end
    op

  end

  desc %{
    -
  }
  tag 'product:paginate'do |tag|
    products_to_paginate = tag.locals.products || tag.locals.tag_products
    radiant_will_paginate products_to_paginate, :cachable_url => true
  end

  # conditional expansion if options
  desc %{
    If there are options on this product, exapnd this tag.
  }
  tag "product:if_options" do |tag|
    unless tag.locals.product.option_sets.empty?
      tag.expand
    else
      ''
    end
  end

  # conditional expansion if no options
  desc %{
    If there are no options on this product, exapnd this tag.
  }
  tag "product:unless_options" do |tag|
    if tag.locals.product.option_sets.empty?
      tag.expand
    else
      ''
    end
  end

  # conditional expansion if call for price
  desc %{
    TODO
  }
  tag "product:if_call_for_price" do |tag|
    if tag.locals.product.call_for_price?
      tag.expand
    else
      ''
    end
  end

  # conditional expansion if not call for price
  desc %{
    TODO
  }
  tag "product:unless_call_for_price" do |tag|
    unless tag.locals.product.call_for_price?
      tag.expand
    else
      ''
    end
  end

  [
    'id',
    'name',
    'slug',
    'weight',
    'sku',
    'description',
    'short_description'
  ].each do |t|
    desc %{
      Renders the product's #{t}.
    }
    tag "product:#{t}" do |tag|
      tag.locals.product.send(t)
    end
  end

  # product price
  desc %{
    -
  }
  tag "product:price" do |tag|
    "%.2f" % tag.locals.product.price
  end

  # product inventory
  desc %{
    This tag allows you to access a product's available inventory. 
    Will return:
     * 'Available' if marked as always available
     * '(number) Available' if quantity is specified
     * 'Out of Stock' if quantity == 0
  }
  tag "product:inventory_message" do |tag|
    p = tag.locals.product
    if p.quantity == -1
      "Available"
    elsif p.quantity == 0
      "Out of Stock"
    else
      "#{p.quantity} Available"
    end
  end
  
  # product dimensions
  desc %{
    This tag allows you to access a product's dimensions (X" x Y" x Z")
  }
  tag "product:dim" do |tag|
    p = tag.locals.product
    "#{p.width}\" x #{p.height}\" x #{p.depth}\""
  end
  
  # add to cart url
  desc %{
    Return the url for adding this to cart
  }
  tag "product:add_to_cart" do |tag|
    %{/cart/add_to_cart/#{tag.locals.product.id}}
  end

  # show all product options as dropdowns
  desc %{
    Show all product options as dropdowns.  Should be inside a form
    that posts to cart/add_to_cart

    attributes: noheader, notable
  }
  tag "product:option_dropdowns" do |tag|
    prod = tag.locals.product

    keys = prod.option_sets.collect{|x| x.name}.sort{|x,y| x <=> y}.collect{|x| "\"#{x.gsub('"', '\\"')}\""}.join(',')

    op = '<script type="text/javascript">'
    op << "var product_#{prod.id}_price = #{prod.price};\n"
    op << "var product_#{prod.id}_keys = [#{keys}];\n"
    op << "var product_#{prod.id}_data = #{prod.available_option_nesting.to_json};\n"
    op << "variations[#{prod.id}] = [];\n"
    op << '</script>'

    unless tag.attr['noheader']
      op << '<h4>Options</h4>'
    end
    unless notable = tag.attr['notable']
      op << '<table class="product_options">'
    end
    prod.option_sets.sort{|x,y| x.name <=> y.name}.each do |x|
      unless notable
        op << "<tr><td>"
      end
      op << "#{x.name}"
      unless notable
        op << "</td><td>"
      end
      op << "<span id=\"variation_#{prod.id}_#{x.name.gsub(/[^\w+]/,'')}\">"
      op << "</span>"
      unless notable
        op << "</td>"
        op << "<td>"
      end
      op << "<input type=\"text\" name=\"option_input[X]\" id=\"variation_#{prod.id}_#{x.name.gsub(/[^\w+]/,'')}_tx\" style=\"display: none\" />"
      op << "</span>"
      unless notable
        op << "</td></tr>"
      end
    end
    unless notable
      op << '</table>'
    end
    op << "<input type=\"hidden\" name=\"options\" id=\"options_#{prod.id}\"/>"
    op << '<script type="text/javascript">'
    op << "make_selection(#{prod.id})"
    op << '</script>'

    op
  end

  # show all product options in a table
  desc %{
    Show all product options in a table as links.

    attributes: noheader
  }
  tag "product:option_table" do |tag|
    prod = tag.locals.product

    keys = prod.option_sets.sort{|x,y| x.name <=> y.name}

    op = ''
    op << '<table class="option">'

    unless tag.attr['noheader']
      op << '<thead><tr>'
      keys.each do |k|
        op << '<th>' << k.name << '</th>'
      end
      op << '<th></th></tr></thead>'
    end

    op << '<tbody>'
    prod.product_option_selections.each do |pos|
      op << '<tr>'
      pos.options.find(:all, :include => 'option_set', :order => 'option_sets.name').each do |o|
        op << '<td>' + o.name + '</td>'
      end
      op << "<td class=\"price\">$#{"%.2f" % (prod.price + pos.options.inject(0.0){|m,x| m + x.price_adjustment})}</td>"
      op << "<td class=\"buynow\"><a href=\"/cart/add_to_cart/#{prod.id}?options=#{pos.id}\">Buy Now</a></td>"
      op << '</tr>'
    end
    op << '</tbody></table>'

    op
  end

  def get_page_by_url_or_param tag

    url = tag.locals.page.request.parameters['url'].last
    if md = url.match(/^page=(\d+)$/)
      rv = md[1].to_i
    else
      rv = tag.locals.page.request.params[:page].to_i
    end

    rv = 1 if rv == 0

    rv
  end
end
