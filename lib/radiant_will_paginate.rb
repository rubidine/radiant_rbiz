require 'will_paginate/view_helpers'

#
# This wraps will_pagiante as radiant_will_paginate, so we can call
# from Radius tags.  The context can be from a actual controller that
# included ExtensionRendersRadiant, or from a Page rendered from
# Radiant's SiteController.
#
# Currently works with mislav-will_paginate = 2.3.4
#
module RadiantWillPaginate
  include ActionView::Helpers::TagHelper

  def radiant_will_paginate entries, options={}
    return nil unless WillPaginate::ViewHelpers.total_pages_for_collection(entries) > 1
    options = options.symbolize_keys.reverse_merge(
                WillPaginate::ViewHelpers.pagination_options
              )
    renderer = RadiantLinkRenderer.new
    renderer.prepare entries, options, self
    renderer.to_html
  end

  class RadiantLinkRenderer < WillPaginate::LinkRenderer

    def page_link_or_span(page, span_class='current', text=nil)
      text ||= page.to_s
      if page and page != current_page
        # A controller that renders radius
        url = @template.instance_variable_get(:@url)

        # A page
        url ||= ActionController::UrlRewriter.new(@template.request, params.clone)

        href = url.rewrite( param_name => page )
        if @options[:cachable_url]
          href, params = href.split('?')

          # filter out any previous page making is way into path
          href = href.split('/')
          href.pop if href.last =~ /^page=\d+$/
          href = href.join('/')
          href << '/' unless href.match(/\/$/)

          # convert page param to path unless it is page 1
          href << params.split('&').reject{|x| x == 'page=1'}.join('/')
        end

        "<a href=\"#{href}\" rel=\"#{rel_value(page)}\">#{text}</a>"
      else
        @template.content_tag :span, text, :class => span_class
      end
    end

    def params
      @params ||= @template.respond_to?(:params) ? \
                    @template.params.to_hash.symbolize_keys : \
                    @template.request.parameters.to_hash.symbolize_keys
    end
  end
end
