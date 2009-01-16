class RadiantConfig < ActiveRecord::Migration
  def self.up
    require File.join(RADIANT_ROOT, 'app', 'models', 'radiant', 'config')
    Radiant::Config['admin.title'] = "RBiz"
    Radiant::Config['admin.subtitle'] = "Open Source eCommerce on Rails"
    Radiant::Config['defaults.page.parts'] = "body"
    Radiant::Config['defaults.page.status'] = "published"
  end

  def self.down
    # Do nothing
  end
end
