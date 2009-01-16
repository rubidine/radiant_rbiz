module SslTags
  include Radiant::Taggable

  desc %{
    Run this loop if request is over SSL
  }
  tag "if_ssl" do |tag|
    tag.expand if tag.locals.page.request.protocol == 'https://'
  end

  desc %{
    Run this loop if request is over plain HTTP
  }
  tag "unless_ssl" do |tag|
    tag.expand if tag.locals.page.request.protocol != 'https://'
  end
end
