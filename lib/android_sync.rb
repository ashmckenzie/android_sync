require 'yaml'
require 'fileutils'
require 'pp'

require File.dirname(__FILE__) + '/string'

class AndroidSync

  attr_accessor :debug, :quiet, :forreal

  # The default YAML configuration file
  #
  DEFAULT_CONFIG = File.dirname(__FILE__) + '/../android_sync.yml'

  # Pretend / dry-run mode
  #
  DEFAULT_FORREAL = false

  # Print output to stdout
  #
  DEFAULT_QUIET = false

  # Print debugging to stdout
  #
  DEFAULT_DEBUG = false

  def initialize(opts = {})  # :nodoc:

    raise Exception, 'Destination must be defined' unless opts[:destination]

    @destination_base = opts[:destination]

    @config_file = opts[:config] ? opts[:config] : DEFAULT_CONFIG

    raise Exception, 'Config file not found' unless File.exists?(@config_file)

    @forreal = ! opts[:forreal].nil? ? opts[:forreal] : DEFAULT_FORREAL
    @quiet = ! opts[:quiet].nil? ? opts[:quiet] : DEFAULT_QUIET
    @debug = ! opts[:debug].nil? ? opts[:debug] : DEFAULT_DEBUG

    @config = YAML.load_file(@config_file)

    @destination = nil
  end

  def run # :nodoc:
    puts unless @quiet
    @config['sources'].each do |s|
      puts "- Looking at #{s['label']}" unless @quiet
      perform_sync(s['source'].rtrim('/'), s['destination'].rtrim('/'), s['keep'])
      puts unless @quiet
    end
  end

  # Sync a bunch of stuff to an Android device (essentially a mounted volume)
  #
  def perform_sync(source, destination, keep=nil)
    new_files, new_files_destination = get_new_files_to_sync(source, destination, keep)
    sync_new_files(source, new_files, new_files_destination)
    cleanup_files_we_dont_want_to_keep(source, new_files, new_files_destination) unless keep.nil?
  end

  # Get a list of source files to examine for sycning
  #
  def get_new_files_to_sync(source, destination, keep=nil)

    # This variable is eval'd using entries setup in the YAML file
    #
    destination_base = @destination_base.rtrim('/')

    new_files_destination = eval('"' + destination + '"').rtrim('/')

    all_new_files = Dir.glob("#{source.rtrim('/')}/**/*").reject { |x| File.directory?(x) }.reverse

    unless keep.nil?
      new_files = all_new_files[0...keep]
    else
      new_files = all_new_files
    end

    [ new_files, new_files_destination ]

  end

  private

  def sync_new_files(source, new_files, new_files_destination)

    new_files_destination_parent = '/' + new_files_destination.split(/\//)[0...-1].join('/').ltrim('/')

    raise "Base destination directory '#{new_files_destination_parent}' does not exist" unless File.directory?(new_files_destination_parent)

    puts "DEBUG: new_files_destination_parent=[#{new_files_destination_parent}]" if @debug

    FileUtils.mkdir_p(new_files_destination) if ! File.directory?(new_files_destination) and @forreal

    new_files.each do |file|
      destination_file = "#{new_files_destination}/#{file.gsub(/#{Regexp.escape("#{source}/")}/, '')}"
      next if File.exists?(destination_file)
      file_parent = destination_file.split(/\//)[0...-1].join('/')
      puts "+ Copying '#{File.basename(file)}' to '#{file_parent}'" unless @quiet
      puts "DEBUG: Copying '#{file} to '#{file_parent}'" if @debug
      if @forreal
        if ! File.exist?(file_parent)
          FileUtils.mkdir_p(file_parent)
        end
        FileUtils.cp(file, destination_file)
      end
    end

  end

  def cleanup_files_we_dont_want_to_keep(source, new_files, new_files_destination)

    source_files = Dir.glob("#{source}/**/*").reject { |x| File.directory?(x) }.collect { |x| x.gsub(/^#{source}\//, '') }.reverse
    new_files.collect! { |x| x.gsub(/^#{source}\//, '') }

    existing_files = Dir.glob("#{new_files_destination}/**/*").reject do |x|
      if File.directory?(x)
        true
      else
        file = x.gsub(/^#{@destination_base}/, '')
        new_files.include?(file) || ! source_files.include?(file)
      end
    end

    existing_files.each do |file|
      puts "! Removing '#{file}'" unless @quiet
      FileUtils.rm_f(file) if @forreal
    end

  end

end
