require 'rcov/rcovtask'

namespace :test do

  desc "Run tests"
  task :run do
    puts %x(rspec -c -f d spec/*_spec.rb)
  end
  
  namespace :coverage do

    desc "Delete aggregate coverage data."
    task(:clean) { rm_f "coverage.data" }

    task :rcov => "test:coverage:clean"

    Rcov::RcovTask.new() do |t|
      t.libs << "test"
      t.test_files = FileList["spec/*_spec.rb"]
      t.output_dir = "coverage/"
      t.verbose = false
      t.rcov_opts << '--aggregate coverage.data --exclude /gems/,/Library/,/usr/,spec,lib/tasks,rubies'
    end

  end

end
