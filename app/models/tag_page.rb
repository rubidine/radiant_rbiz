class TagPage < Page

  def virtual? ; true ; end

  def title
    @browsing_tags ? \
      @browsing_tags.collect{|x| x.name}.join(', ') : \
      read_attribute('title')
  end

  def process request, response
    @request, @response = request, response
    tags = load_tags
    products = nil

    options = options_from_params_and_page_configuration_and_cart_config

    unless tags.empty?
      products = load_products_by_tags(tags, options)
    else
      products = load_products(options)
    end

    lazy_initialize_parser_and_context
    @context.globals.tag_products = products
    @context.globals.browsing_tags = tags
    @context.globals.related_tags = Tag.related_for(tags)

    # for title
    @browsing_tags = tags unless tags.empty?

    super
  end

  def load_products_by_tags tags, options
    products = nil
    product_ids = Product.find_ids_by_tags(tags)
    if product_ids.empty?
      products = WillPaginate::Collection.new(
                   1,                  # current page
                   options[:per_page], # per page
                   0                   # total pages
                 )
    else
      options[:conditions] ||= {}
      options[:conditions].merge!(:id => product_ids)
      options[:total_entries] = product_ids.length
      products = Product.paginate(options)
    end

    products
  end

  def load_products options
    Product.available.paginate(options)
  end

  # For will_paginate
  def params
    @params ||= filter_params(@request.parameters)
  end

  # For will_paginate
  def page
    (@page ||= 1).to_i
    @page.to_i
  end

  def find_by_url(url, live=true, clean=true)
    url = clean_url(url) if clean
    m = url.match(/^#{self.url}(.*)$/)
    if m
      if child=children.find_by_slug(m[1]) and child.published?
        child
      else
        self
      end
    else
      super
    end
    # No code here, retrun from condition #
  end

  # modify the url to have /x=y/ parts assigned @x = y
  # and removed from params[:url]
  def filter_params p
    rv = p.dup
    while rv[:url].last.match(/=/)
      param = rv[:url].pop
      name, value = param.split(/=/)
      instance_variable_set("@#{name}", value)
    end
    rv
  end

  def load_tags
    u = params[:url].dup

    # remove the part of the url that got to this page
    self.url.split('/').reject{|x|x.empty?}.length.times{ u.shift }

    # everything else in the url is a tag slug
    rv = u.collect{|x| Tag.find_by_slug(x)}
    rv.compact!

    rv
  end

  def load_configuration
    return @config if @config

    part = parts.find_by_name('config')
    unless part
      @config = {}
      return @config
    end

    @config = YAML.load(part.body) rescue {}
    @config.symbolize_keys!
    @config
  end

  def options_from_params_and_page_configuration_and_cart_config
    conf = load_configuration

    # Clean up order if it comes from the url
    @order = clean_sql_order(@order) if @order

    {
      :page => (@page || 1).to_i,
      :per_page => (
        @per_page || \
        conf[:per_page] || \
        CartConfig.get(:products_per_page, :store)
      ).to_i,
      :order => (@order || conf[:order] || 'featured, slug')
    }
  end

  def clean_sql_order order
    valid_names = Product.columns.collect{|x| x.name}
    ordering = ['ASC', 'DESC']
    ord = []

    order.split(',').each do |col|
      cc = col.split(' ')

      # mycolumn
      # mycolumn desc
      next if cc.length > 2

      # if it is a valid column, put it in ord[]
      if valid_names.include?(col = cc.first)
        rv = Product.connection.quote_column_name(col)
        if cc.length == 2 and ordering.include?(order = cc.last.upcase)
          rv << " #{order}"
        end
        ord << rv
      end

    end

    ord.join(',')
  end
end
