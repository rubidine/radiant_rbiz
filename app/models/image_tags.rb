module ImageTags
  include Radiant::Taggable

  # default image accessor
  desc %{
    Access the default product image.

    *Usage*:
    
    <pre><code><r:product id="3"><r:image><r:path /></r:image></r:product></code></pre>
    <pre><code><r:product id="3"><r:image><r:path thumbnail="1"/></r:image></r:product></code></pre>
  }
  tag "product:image" do |tag|
    tag.locals.image = tag.locals.product.default_image
    tag.expand
  end

  # image path
  desc %{
    Show the relative path for an image.
    (Prefix defaults to '', see example)
    Use thumbnail=1 to show thumbnail

    *Usage*:
    
    <pre><code><r:product id="3"><r:image><r:path /></r:image></r:product></code></pre>
    <pre><code><r:product id="3"><r:image><r:path thumbnail="1" /></r:image></r:product></code></pre>
    <pre><code><r:product id="3"><r:image><r:path prefix="/some/path" /></r:image></r:product></code></pre>
  }
  tag "product:image:path" do |tag|
    filepath = tag.attr['prefix'] || ''
    i = tag.locals.image
    if i and tag.attr['thumbnail']
      i = i.thumbnail? ? i : i.twin
    end
    filename = i ? i.image_path : "#{'s' if tag.attr['thumbnail']}unavailable.jpg"
    File.join(filepath, filename)
  end

  # image alt text
  desc %{
    Alternate text
  }
  tag "product:image:alt" do |tag|
    i = tag.locals.image
    i ? i.image_alt : 'Photo coming soon!'
  end

  # image itteration
  desc %{
    Show all images for a product
    Use 'ignore_default="1"' to hide default image
    Use 'thumbnail="1"' to show thumbnails

    *Usage*:
    
    <pre><code><r:product id="3"><r:image:each><r:path /></r:image:each></r:product></code></pre>
  }
  tag "product:image:each" do |tag|
    p = tag.locals.product
    op = ''
    imgs = tag.attr['thumbnail'] ? p.thumbnails : p.images
    if tag.attr['ignore_default']
      imgs -= tag.attr['thumbnail'] ? [p.default_thumbnail] : [p.default_image]
    end
    imgs.each do |i|
      tag.locals.image = i
      op << tag.expand
    end
    op
  end
end
