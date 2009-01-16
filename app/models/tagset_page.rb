class TagsetPage < Page
  def virtual? ; true ; end

  def find_by_url(url, live=true, clean=true)
    url = clean_url(url) if clean
    m = url.match(/^#{self.url}(.+)\/$/)
    if m
      if child=children.find_by_slug(m[1]) and child.published?
        child
      else
        tagset = TagSet.find_by_slug(m[1])
        if tagset
          lazy_initialize_parser_and_context
          @context.globals.tagset = tagset
          self
        else
          super
        end
      end
    else
      super
    end
  end

end
