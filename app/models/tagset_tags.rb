module TagsetTags 
  include Radiant::Taggable

  desc %{
    Find a tagset
  }
  tag "tagset" do |tag|
    if tag.attr['id']
      tag.locals.tagset = TagSet.find(tag.attr['id'])
    elsif tag.attr['name']
      tag.locals.tagset = TagSet.find_by_name(tag.attr['name'])
    end

=begin
    if tag.locals.tagset.nil?
      raise "NO TAGSET #{tag.inspect}"
    end
=end

    tag.expand
  end

  desc %{
    Cycles through each tagset
    
    *Usage:*
    <pre><code><r:tagset:each [offset="number"] [limit="number"] [by="attribute"] [order="asc|desc"]>
     ...
     </r:tagset:each>
    </code></pre>
  }
  tag "tagset:each" do |tag|
    opts = {}
    
    if tag.attr['by']
      opts[:order] = tag.attr['by']
    else
      opts[:order] = "id"
    end
    
    if tag.attr['order']
      opts[:order] += " #{tag.attr['order']}"
    end
    
    if tag.attr['limit']
      opts[:limit] = tag.attr['limit']
    end

    if tag.attr['offset']
      opts[:offset] = tag.attr['offset']
    end

    op = ''
    TagSet.find(:all, opts).each do |t|
      tag.locals.tagset = t
      op << tag.expand
    end
    op
  end

  ['name', 'slug', 'description', 'short_description'].each do |t|
    desc %{
      Print the #{t} of a tagset

      *USAGE*

      <pre><code><r:tagset:each><r:#{t} /></r:tagset:each></code></pre>
    }
    tag "tagset:#{t}" do |tag|
      tag.locals.tagset.send(t)
    end
  end

  desc %{
    Cycles through each tag of the current tagset.
    
    *Usage:*
    <pre><code><r:tagset:each_tag [offset="number"] [limit="number"] [by="attribute"] [order="asc|desc"]>
     ...
     </r:tagset:each_tag>
    </code></pre>
  }
  tag "tagset:each_tag" do |tag|
=begin
    if tag.attr["name"]
      ts = TagSet.find_by_name(tag.attr["name"])
    elsif tag.attr['id']
      ts = TagSet.find(tag.attr["id"])
    elsif tag.attr['slug']
      ts = TagSet.find_by_slug(tag.attr['slug'] || tag.locals.page.slug)
    else
      ts= tag.locals.tagset
    end
=end
    opts = {}
    
    if tag.attr['by']
      opts[:order] = tag.attr['by']
    else
      opts[:order] = "id"
    end
    
    if tag.attr['order']
      opts[:order] += " #{tag.attr['order']}"
    end
    
    if tag.attr['limit']
      opts[:limit] = tag.attr['limit']
    end

    if tag.attr['offset']
      opts[:offset] = tag.attr['offset']
    end

    op = ''
#    ts.tags.each do |t|
    tag.locals.tagset.tags.find(:all, opts).each do |t|
      tag.locals.tag = t
      op << tag.expand
    end
    op
  end

  # itterate over products for a tagset
  desc %{
    Cycles through each product of the current tagset.
    
    *Usage:*
    <pre><code><r:tagset:each_product [offset="number"] [limit="number"] [by="attribute"] [order="asc|desc"]>
     ...
     </r:tagset:each_product>
    </code></pre>
  }
  tag "tagset:each_product" do |tag|
    opts = {
    :conditions => [
               'effective_on IS NOT NULL AND effective_on <= ? AND
               (ineffective_on IS NULL OR ineffective_on > ?)',
               Date.today, Date.today
      ]
    }
    
    if tag.attr['by']
      opts[:order] = tag.attr['by']
    else
      opts[:order] = "id"
    end
    
    if tag.attr['order']
      opts[:order] += " #{tag.attr['order']}"
    end
    
    if tag.attr['featured']
      opts[:conditions].first << ' AND featured = ?'
      opts[:conditions] << ((tag.attr['featured'].to_i == 1) ? true : false)
    end
    
    if tag.attr['limit']
      opts[:limit] = tag.attr['limit']
    end

    if tag.attr['offset']
      opts[:offset] = tag.attr['offset']
    end
        
    products = tag.locals.tagset.products.find(:all, opts)

    op = ''
    products.each do |p|
      tag.locals.product = p  
      op << tag.expand
    end

    op
  end
end
