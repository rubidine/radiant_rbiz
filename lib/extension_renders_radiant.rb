# Include ExtensionRendersRadiant in a controller to allow it to use
# pages stored in RadiantCMS for actions that are performed in the controller.
# If no page exists in Radiant, the default template will be used.
#
# A key of :assigns => {:key => val...} can be passed to render to
# set tag.locals.key in the rendered page.
#
# Special IVARS (that can be set through a filter, etc)
#   @radiant_method_assigns -> call named method and result is assigned
#   @radiant_page_assignments -> named ivar :@var is assigned
#   @radiant_cache_page -> rendered pages by defualt skip cache, override
module ExtensionRendersRadiant

  DEFAULT_METHOD_ASSIGNS = [:flash, :params]
  DEFAULT_IVAR_ASSIGNS = []

  # This is method chained to render
  # so args will be anything a render call can take
  def render_with_extension_renders_radiant *args
    unless render_radiant_page(*args)
      render_without_extension_renders_radiant *args
    end
  end

  # Do default check for file.
  # If no file, then check radiant.
  # Do not check layouts.
  def template_exists_with_extension_renders_radiant?(t=default_template_name)
    r = template_exists_without_extension_renders_radiant?(t)
    return r if r
    return nil if t.match(/^layouts\//)
    url = "/#{t}"
    # We have to rescue because we could get a MissingRootPageError
    page = Page.find_by_url(url) rescue nil
    return (page and !page.is_a?(FileNotFoundPage))
  end

  # render from radiant if possible.
  # return nil if false.
  # args can be anything from render()
  def render_radiant_page *args
    ad = (args.length == 1) ? args.first.dup : {}
    action = ad.delete(:action)
    split_action = action ? action.split('/') : []

    # if :action isn't specified, render for /controller/action
    split_action.unshift params[:action] if split_action.empty?

    # either built from scratch or :action=>'action' (not '/controller/action')
    # assume we want controller name in the url (seems reasonable)
    # and not root level page
    split_action.unshift params[:controller] if split_action.length < 2

    url = '/' + split_action.join('/')

    # We have to rescue because we could get a MissingRootPageError
    page = Page.find_by_url(url) rescue nil
    return false if page.nil? or page.is_a?(FileNotFoundPage)

    # collect data to assign to page
    assigns = {}

    # collect values that are returend from methods in the controller
    # we are currently called from
    # @radiant_method_assigns could be set with before_filter
    to_assign = DEFAULT_METHOD_ASSIGNS
    to_assign += @radint_method_assigns if @radiant_method_assigns
    to_assign.each do |x|
      assigns[x] = self.send(x)
    end

    # collect values that are set in ivars (@var) in the current controller
    # @radiant_page_assignments could be set with before_filter
    to_assign = DEFAULT_IVAR_ASSIGNS
    to_assign += @radiant_page_assignments if @radiant_page_assignments
    to_assign.each do |x|
      assigns[x] = self.instance_variable_get("@#{x}")
    end

    # @radiant page values can be set in a before_filter
    # and are just {:key => value} (no method call or ivar required)
    assigns.merge!(@radiant_page_values) if @radiant_page_values

    # render :assigns => {:key => value} will throw more stuff at the page
    if extra_assigns = ad.delete(:assigns)
      assigns.merge!(extra_assigns)
    end

    page.send(:lazy_initialize_parser_and_context)
    context = page.instance_variable_get(:@context)
    assigns.each do |k,v|
      context.globals.send "#{k}=", v
    end

    # WillPaginate loves this
    page.instance_variable_set(
      :@url,
      ActionController::UrlRewriter.new(request, params.clone)
    )

    # again, set through a before_filter or such
    unless @radiant_cache_page
      def page.cache? ; false ; end
    end
    page.process(request, response)
    @performed_render = true
    true
  end

  def self.included(kls)
    kls.send :alias_method_chain, :render, :extension_renders_radiant
    kls.send :alias_method_chain, :template_exists?, :extension_renders_radiant
  end
end
