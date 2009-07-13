unless defined?(Dispatcher)
  require 'dispatcher'
end
unless defined?(ActionController::Dispatcher)
  ActionController::Dispatcher = Dispatcher
end

require 'csv'
require 'ostruct'
if ENV['RAILS_ENV'] == 'test'
  require 'test/spec'
  require 'mocha'
end

require 'will_paginate'

class RadiantRbizExtension < Radiant::Extension

  version "1.0"
  description "Radiant integration for RBiz"
  url "http://github.com/rubidine/rbiz"
  
  def activate

    # Add links to header on every page
    OfficeViewExtender.register '/common/header', :partial => 'office/radiant_nav'
    OfficeViewExtender.register '/common/header', :partial => 'office/radiant_js'

    admin.tabs.add "Cart Office", "/office", :after => "Layouts", :visibility => [:all]

    # Protect from forgery and Radiant's use of ActiveRecordStore don't mix
    # maybe this has changed by 0.6.7 ?
#    CustomerController.send :skip_before_filter, :verify_authenticity_token
#    CartController.send :skip_before_filter, :verify_authenticity_token

    # Cart and customer don't need a radiant login
    CartController.send :no_login_required
    CustomerController.send :no_login_required

    # Cart and customer render radiant
    CartController.send :include, ExtensionRendersRadiant
    CustomerController.send :include, ExtensionRendersRadiant

    # Cart has some page assignments to make
    CartController.send :include, RadiantCartController

    # Load Page subclasses
    ProductPage
    TagsetPage
    TagPage

    # Load radius tags
    tags_dir = File.join(File.dirname(__FILE__), 'app', 'models')
    Dir["#{tags_dir}/*_tags.rb"].each do |fn|
      Page.send :include, File.basename(fn, '.rb').camelize.constantize
    end

    # If using share_layouts extension, activate it
    if ActionController::Base.respond_to? :radiant_layout
      tpl = CartConfig.get(:cart_layout, :radiant) || 'Normal'

      CartController.send :radiant_layout, tpl
      CustomerController.send :radiant_layout, tpl

      default_title_and_breadcrumbs = lambda {
        @title = "Cart"
        @breadcrumbs = []
      }
      CartController.send :before_filter, &default_title_and_breadcrumbs
      CustomerController.send :before_filter, &default_title_and_breadcrumbs
    end
    
    [
      Office::CartConfigsController,
      Office::CartsController,
      Office::CouponsController,
      Office::CustomersController,
      Office::ErrorMessagesController,
      Office::GatewayController,
      Office::OptionsController,
      Office::OptionSetsController,
      Office::ProductImagesController,
      Office::VariationsController,
      Office::ProductsController,
      Office::TagActivationsController,
      Office::TagsController,
      Office::TagSetsController
    ].each do |controller|
      # Office renders like the rest of the radiant backend
      controller.send :layout, 'application'

      # remove standalone-style access-control to office
      controller.send :skip_before_filter, :office_login_requirement
    end
    
  end
  
  def deactivate
    admin.tabs.remove "Cart Office"
    OfficeViewExtender.unregister '/common/header', :partial => 'office/radiant_nav'
    OfficeViewExtender.unregister '/common/header', :partial => 'office/radiant_js'
  end
  
end
