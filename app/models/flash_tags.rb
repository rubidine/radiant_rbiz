module FlashTags
  include Radiant::Taggable

  desc 'Show this section if there are flashes'
  tag "if_flash" do |tag|
    if tag.locals.flash and !tag.locals.flash.empty?
      tag.expand 
    else
      ''
    end
  end

  # just a conatiner
  tag 'flash' do |tag|
    tag.expand
  end

  desc 'Loop over each flash.  Enables flash:key and flash:message tags.'
  tag 'flash:each' do |tag|
    rv = ''
    tag.locals.flash.each do |k,v|
      tag.locals.flash_key = k
      tag.locals.flash_message = v
      rv << tag.expand
    end
    rv
  end

  desc 'Show the key of the current flash.'
  tag 'flash:key' do |tag|
    tag.locals.flash_key
  end

  desc 'Show the message of the current flash.'
  tag 'flash:message' do |tag|
    tag.locals.flash_message
  end
end
