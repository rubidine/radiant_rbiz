module PageDataTags
  include Radiant::Taggable

  desc %{
    Page data is a generic datastructure that holds data for a certain action.
    The contents of the data vary by the page being viewed.

    Use the 'name' attribute to get the data you're looking for.
  }
  tag 'page_data' do |tag|
    if tag.attr['name']
      tag.locals.page.page_data[tag.attr['name']]
    else
      tag.expand
    end
  end

  desc %{
    Only show the contained content if
    the named field is set and is not false
  }
  tag 'page_data:if' do |tag|
    raise 'Specify name' unless tag.attr['name']
    if tag.locals.page.page_data[tag.attr['name']]
      tag.expand
    end
  end

  desc %{
    Only show the contained content if
    the named field is set and is non-zero
  }
  tag 'page_data:if_nonzero' do |tag|
    raise 'Specify name' unless tag.attr['name']
    if x=tag.locals.page.page_data[tag.attr['name']] and x != 0
      tag.expand
    end
  end

  desc %{
    Only show the contained content if
    the named field is set and is greater than zero
  }
  tag 'page_data:if_gt_zero' do |tag|
    raise 'Specify name' unless tag.attr['name']
    if x=tag.locals.page.page_data[tag.attr['name']] and x > 0
      tag.expand
    end
  end

  desc %{
    Only show the contained content if
    the named field is set and is equal to zero
  }
  tag 'page_data:if_eq_zero' do |tag|
    raise 'Specify name' unless tag.attr['name']
    if x=tag.locals.page.page_data[tag.attr['name']] and x == 0
      tag.expand
    end
  end

end
