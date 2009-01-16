module TagTags 
  include Radiant::Taggable

  # basic tag
  desc "find a tag by id"
  tag "tag" do |tag|
    if tag.attr['id']
      tag.locals.tag = Tag.find(tag.attr['id'])
    end
    tag.expand
  end

  # attributes of the tag
  ['name', 'slug', 'short_description', 'full_description'].each do |t|
    desc %{
      Show the #{t} of a tag.

      *Usage*

      <pre><code><r:tag id="3"><r:#{t} /></r:tag></code></pre>
    }
    tag "tag:#{t}" do |tag|
      tag.locals.tag.send(t)
    end
  end

  # itterate over all products for a tag
  desc %{
    Cycles through each product of the current tag.
    
    *Usage:*
    <pre><code><r:tag:each_product [offset="number"] [limit="number"] [by="attribute"] [order="asc|desc"]>
     ...
     </r:tag:each_product>
    </code></pre>
  }
  tag "tag:each_product" do |tag|
    op = ''
    opts = {
      :conditions => [
        'effective_on IS NOT NULL AND effective_on <= ?
        AND (ineffective_on IS NULL OR ineffective_on > ?)',
        Date.today, Date.today
      ]
    }
    
    if tag.attr['by']
      opts[:order] = tag.attr['b']
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

    products = tag.locals.tag.products.find(:all, opts)
    products.each do |p|
      tag.locals.product = p
      op << tag.expand
    end
    op
  end


#  desc 'Loop over each tag (on a TagPage) [related=1]'
  desc %{
    Cycles through each tag.
    
    *Usage:*
    <pre><code><r:tag:each [offset="number"] [limit="number"] [by="attribute"] [order="asc|desc"]>
     ...
     </r:tag:each>
    </code></pre>
  }
  
  tag 'tag:each' do |tag|

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

    rv = ''
    Tag.find(:all, opts).each do |t|
     #tag.locals.send(tag.attr['related'] ? :browse_tags : :related_tags).each do |t|
      tag.locals.tag = t
      rv << tag.expand
    end
    rv
  end
end
