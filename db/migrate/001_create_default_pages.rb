class CreateDefaultPages < RadiantPageUpdater
  def self.up
    unless p = Page.find_by_parent_id(nil)
      Page.create! :slug => '/', :title => 'Homepage', :breadcrumb => 'Homepage'
    end
    fname = File.join(File.dirname(__FILE__), '..', 'pages.yml')
    fdata = File.read(fname)
    default_pages = YAML.load(fdata)
    default_pages.each do |page, parts|
      if page.is_a?(Hash)
        options = page.values.first
        page = page.keys.first
      else
        options = {}
      end
      find_or_create_page(page, options) do |pg|
        parts.each do |name, body|
          pg.create_part(name, body) unless pg.has_part?(name)
        end
      end
    end
  end

  def self.down
    # Leave the pages in!
  end
end
