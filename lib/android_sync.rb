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

  # Pretend / dry-run mode
  #
  DEFAULT_PRETEND = false

  DEFAULT_VERBOSE = true

  DEFAULT_DEBUG = false

  def initialize(opts)  # :nodoc:

    @destination = opts[:destination]
    @config_file = opts[:config] || DEFAULT_CONFIG
    @pretend = opts[:pretend] || DEFAULT_PRETEND
    @verbose = opts[:verbose] || DEFAULT_VERBOSE
    @debug = opts[:debug] || DEFAULT_DEBUG

    @config = YAML.load_file(@config_file)
  end

  # Sync a bunch of stuff to an Android device (essentially a mounted volume)
  #
  def run

    puts

    destination = @destination.trim('/')

    @config['sources'].each do |source|

      puts "- Looking at #{source['label']}"
      
      final_destination = eval('"' + source['destination'] + '"').trim('/') + '/'
      FileUtils.mkdir_p(final_destination) unless File.directory?(final_destination) and @pretend

      all_new_files = Dir.glob("#{source['source'].trim('/')}/*").sort { |x, y| File::stat(y).ctime <=> File::stat(x).ctime }

      unless source['keep'].nil?
        new_files = all_new_files[0...source['keep']]
      else
        new_files = all_new_files
      end

      sync_files(new_files, final_destination)

      cleanup(final_destination, new_files) unless source['keep'].nil?

      puts

    end

  end

  private

  def sync_files(new_files, destination)

    new_files.each do |file|
      next if File.exists?("#{destination}/#{File.basename(file)}")
      cmd = "rsync -vax#{@pretend ? 'n' : ''} \"#{file}\" \"#{destination}\""
      puts "+ Syncing '#{File.basename(file)}' to '#{destination}'" if @verbose
      output = `#{cmd}`
      puts "# #{cmd}" if @debug
    end

  end

  def cleanup(destination, new_files)

    existing_files = Dir.glob("#{destination}*").sort { |x, y| File::stat(y).ctime <=> File::stat(x).ctime }.reject do |file|
      new_files.collect { |x| File.basename(x) }.include?(File.basename(file))
    end

    existing_files.each do |file|
      puts "! Removing '#{file}'"
      FileUtils.rm_f(file) unless @pretend
    end

  end

end
