require 'yaml'
require 'fileutils'
require 'pp'

class String

  def trim(chars)
    self.gsub(/#{chars}*$/, '')
  end

end

class AndroidSync

  # The default YAML configuration file
  #
  DEFAULT_CONFIG = File.dirname(__FILE__) + '/../android_sync.yml'

  def initialize(opts)  # :nodoc:

    @destination = opts[:destination]
    @config_file = opts[:config] || DEFAULT_CONFIG
    @verbose = opts[:verbose] || true

    @config = YAML.load_file(@config_file)
  end

  # Sync a bunch of stuff to an Android device (essentially a mounted volume)
  #
  def run

    puts

    @config['sources'].each do |source|

      puts "- Attempting to sync #{source['label']}"
            
      destination = @destination.trim('/')
      
      final_destination = eval('"' + source['destination'] + '"').trim('/') + '/'
      all_new_files = Dir.glob("#{source['source'].trim('/')}/*").sort { |x, y| File::stat(y).ctime <=> File::stat(x).ctime }

      unless source['keep'].nil?
        new_files = all_new_files[0...source['keep']]
      else
        new_files = all_new_files
      end

      new_files.each do |file|
        next if File.exists?("#{final_destination}/#{File.basename(file)}")
        cmd = "rsync -vax \"#{file}\" \"#{final_destination}\""
        puts "+ Syncing '#{File.basename(file)}' to '#{final_destination}'" if @verbose
        output = `#{cmd}`
      end

      unless source['keep'].nil?

        existing_files = Dir.glob("#{final_destination}*").sort { |x, y| File::stat(y).ctime <=> File::stat(x).ctime }.reject do |file|
          new_files.collect { |x| File.basename(x) }.include?(File.basename(file))
        end

        existing_files.each do |file|
          puts "! Removing '#{file}'"
          FileUtils.rm_f(file)
        end

      end

      puts

    end

  end

end
