# RadiantPageUpdater runs in an ActiveRecord::Migration to
# migrate RadiantCMS pages.  Version numbers are tracked in comments
# on the page.  Radiant Extensions can update a page as well, and their
# changes are tracked as well.
class RadiantPageUpdater < ActiveRecord::Migration

  class PageNotFoundForUpdateError < StandardError ; end
  class PagePartNotFoundForUpdateError < StandardError ; end
  class PagePartHasBeenModifiedError < StandardError ; end
  class PagePartDidNotMatchExpectedContentError < StandardError ; end

  # If a page exists, return it (optionally yeild it)
  # otherwise create a heirarchy for it and make it.
  # By default will be a draft
  #
  # Options is a hash of attributes to create the page with
  # (if it is created), with the following extras
  # * publish => true to mark the page as published if created
  def self.find_or_create_page url, options = {}
    catch_errors do
      page = Page.find_by_url(url, false)
      page = nil if page.is_a?(FileNotFoundPage)
      if page
        page = migration_page(page)
        yield page if block_given?
        return page
      end

      parts = url.split('/')
      slug = parts.pop || '/'
      parts = parts.empty? ? nil : parts.join('/')
      parent = parts ? find_or_create_page(parts.empty? ? '/' : parts) : nil


      options = options.reverse_merge(
                  :breadcrumb => slug,
                  :slug => slug,
                  :class_name => 'Page',
                  :lock_version => 0,
                  :title => slug,
                  :status_id => Status['Draft'].id,
                  :title => slug,
                  :virtual => false,
                  :parent => parent
                )

      if publish = options.delete(:published)
        options[:status_id] = Status['Published'].id
        options[:published_at] ||= Time.now
      end

      p = Page.create!(options)
      p = migration_page(p)

      yield p if block_given?

      return p
    end
  end

  # Given the url of a page and the name of a part (like 'body')
  # Options can be
  # * extension => name of extension changing the page
  def self.update_page_part url, part, options = {}
    catch_errors do
      part = find_page_part(url, part)
      return unless part_is_updatable?(part, options)
      runner = build_runner_for_update(part, options)
      yield runner
      part.content = runner.process
      if options[:extension]
        update_extension_version(
          part,
          options[:extension],
          options[:extension_version]
        )
      end
      part.save!
    end
  end

  private

  def self.part_is_not_versioned? part
    parse_version_from_part(part).nil?
  end

  # Let us know if a page part can be updated, or if a user has modified it.
  # Parts should have an <r:comment>version=X</r:comment> stanza at the beginnig
  # unless it has been updated by the user
  def self.part_is_updatable? part, options
    version = parse_version_from_part(part)
    ev = parse_extension_versions_from_part(part)[options[:extension]]

    if version and options[:version] \
    and (version == options[:version] \
    or (version > options[:version] and !options[:going_down]))
      return false
    end

    if options[:minimum_version] \
    and options[:minimum_version] > (version || 0)
      return false
    end

    if options[:maximum_version] \
    and options[:maximum_version] < (version || 0)
      return false
    end

    if options[:only_versions] \
    and !options[:only_versions].include?(version || 0)
      return false
    end
    if options[:not_versions] and options[:not_versions].include?(version)
      return false
    end

    if ev
      if options[:minimum_extension_version] \
      and options[:minimum_extension_version] > ev
        return false
      end

      if options[:maximum_extension_version] \
      and options[:maximum_extension_version] < ev
        return false
      end

      if options[:only_extension_versions] \
      and !options[:only_extension_versions].include?(ev)
        return false
      end

      if options[:not_extension_versions] \
      and options[:not_extension_versions].include?(ev)
        return false
      end

      if options[:extension_version] \
      and (ev == options[:extension_version] \
      or (ev > options[:extension_version] and !options[:going_down]))
        return false
      end
    end

    true
  end

  def self.parse_version_from_part part
    md = part.content.match(/^\s*<r:comment>VERSION=(\d+)<\/r:comment>/)
    (md and md[1]) ? md[1].to_i : nil
  end

  def self.parse_extension_versions_from_part part
    rv = {}
    part.content.each_line do |line|
      md = line.match(/^\s*<r:comment>EXTENSION\[([^\]]+)\]=(\d+)<\/r:comment>/)
      if md and md[1] and md[2]
        rv[md[1]] = md[2].to_i
      end
    end
    rv
  end

  def self.update_extension_version part, extension, version=nil
    if version.nil?
      version = (parse_extension_versions_from_part(part)[extension] || 0) + 1
    end
    key = /^\s*<r:comment>EXTENSION\[#{extension}\]=\d+<\/r:comment>\s*$/
    replace = "<r:comment>EXTENSION[#{extension}]=#{version}</r:comment>"
    if part.content.match(key)
      part.content = part.content.gsub(key, replace)
    else
      lines = part.content.split("\n")
      part.content = (lines[0,1] + [replace] + lines[1..-1]).join("\n")
    end
  end

  def self.update_version part, version=nil
    if version.nil?
      version = (parse_version_from_part(part) || 0) + 1
    end
    key = /^\s*<r:comment>VERSION=\d+<\/r:comment>\s*$/
    replace = "<r:comment>VERSION=#{version}</r:comment>"
    if part.content.match(key)
      part.content = part.content.gsub(key, replace)
    else
      lines = part.content.split("\n")
      part.content = ([replace] + lines).join("\n")
    end
  end

  # Run a block and log any errors it throws
  def self.catch_errors
    begin
      yield
    rescue Exception => ex
      log_error(ex)
    end
  end

  # By default, log errors to console, but this could easily be metaprogrammed
  def self.log_error exception
    STDERR.puts "#{exception.class.name}: #{exception.message}"
    STDERR.puts "\t" + exception.backtrace.join("\n\t")
  end

  def self.find_page_part url, part
    page = Page.find_by_url(url, false)
    if page.nil? or page.is_a?(FileNotFoundPage)
      raise PageNotFoundForUpdateError, "Unable to find #{url}"
    end

    part = page.parts.find_by_name(part)
    if part.nil?
      raise PagePartNotFoundForUpdateError, "Unable to find #{url}##{part}"
    end
    if part_is_not_versioned?(part)
      raise PagePartHasBeenModifiedError, "User has modified #{url}##{part}"
    end
    part
  end

  def self.build_runner_for_update(part, options)
    runner = UpdateRunner.new
    runner.part = part
    runner.part_version = parse_version_from_part(part)
    if options[:extension]
      runner.extension = options[:extension]
      evs = parse_extension_versions_from_part(part)
      runner.extension_version = evs[options[:extension]] || 0
    end
    runner
  end

  def self.migration_page(pg)
    class << pg
      def create_part name, body
        rv = parts.create!(:name => name, :content => body)
        RadiantPageUpdater.update_version(rv)
        rv.save
        yield rv if block_given?
        rv
      end

      def has_part name
        parts.find_by_name(name)
      end
    end

    pg
  end

  # Update runner is given the page part.
  # The attr_accessor values are set based on how it should be processed.
  # Content is what to put in the page, sentinels are where to find
  # what to replace.
  class UpdateRunner
    attr_accessor :content
    attr_accessor :leadin_sentinel
    attr_accessor :leadout_sentinel
    attr_accessor :replace_sentinel
    attr_accessor :extension
    attr_accessor :extension_version
    attr_accessor :part
    attr_accessor :part_version

    class MissingSentinelError < StandardError ; end
    class MissingContentError < StandardError ; end

    # Return the new body, with the substitution done
    def process
      if leadin_sentinel.nil?   \
      and leadout_sentinel.nil? \
      and replace_sentinel.nil?
        raise MissingSentinelError, "No leadin/leadout/replace sentinel given."
      end
      if content.nil?
        raise MissingContentError, "No content for update."
      end
      insert_content(part.content)
    end

    private
    # return the changed body
    def insert_content body
      idx, str = index_and_text_of_sentinel_match(body)

      # add leadin length to first part
      idx += str.length if leadin_sentinel

      # where the tail should start
      idx2 = idx

      # start after match if we are replacing it
      idx2 += str.length if replace_sentinel

      body[0,idx] + content + body[idx2..-1]
    end

    # location to perform the content insertion
    def index_and_text_of_sentinel_match body
      sen = leadin_sentinel || leadout_sentinel || replace_sentinel
      if sen.is_a?(Regexp)
        if md = body.match(sen)
          return body.index(md[0]), md[0] 
        end
      elsif sen.is_a?(String)
        if rv = body.index(sen)
          return rv, sen
        end
      else
        raise "Unknown sentinel type: #{sen.class.name} - Use Regexp or String"
      end

      raise PagePartDidNotMatchExpectedContentError,
            "Expected #{part.page.url}##{part.name} to match #{sen}"
    end
  end
end
