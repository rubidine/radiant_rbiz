namespace :radiant do
  namespace :extensions do
    namespace :radiant_rbiz do
      
      desc "Runs the migration of the Radiant RBiz extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          RadiantRbizExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          RadiantRbizExtension.migrator.migrate
        end
      end
      
      desc "Copies initializers of the Radiant RBiz to the instance config/initializers directory."
      task :initializers => :environment do
        is_git_or_dir = proc {|path| path =~ /\.git/ || File.directory?(path) }
        mkdir_p RAILS_ROOT + '/config/initializers'
        Dir[RadiantRbizExtension.root + "/lib/tasks/initializers/*"].reject(&is_git_or_dir).each do |file|
          path = file.sub(RadiantRbizExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          cp file, RAILS_ROOT + '/config/initializers' 
        end
      end  

      desc "Copies public assets of the Radiant RBiz to the instance public/ directory."
      task :update => :environment do
        is_git_or_dir = proc {|path| path =~ /\.git/ || File.directory?(path) }
        Dir[RadiantRbizExtension.root + "/public/**/*"].reject(&is_git_or_dir).each do |file|
          path = file.sub(RadiantRbizExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  

      desc "Perform all operations to install the Radiant RBiz extension"
      task :install => [:migrate, :update] do
      end

    end
  end
end

# include plugin tasks that are within this extension
root = File.join(File.dirname(__FILE__), '..', '..')
Dir[root + '/vendor/plugins/*/tasks/*.rake'].sort.each { |ext| load ext }
