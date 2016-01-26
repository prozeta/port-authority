disabled_checks = %w( 80chars
                      documentation
                      single_quote_string_with_variables
                      autoloader_layout
                      ensure_first_param
                      puppet_url_without_modules
                      case_without_default
                      nested_classes_or_defines )

task :default => :help

desc 'Help'
task :help do
  sh 'rake -T'
end

namespace :puppet do
  desc 'Run tests'
  task :test do
    require './puppet-test'
    PuppetTester.new('puppet/', disabled_checks).run
  end

  desc "Fix what's possible by puppet-lint"
  task :lint do
    runcmd = [
      'puppet-lint',
      '--error-level', 'error'
    ] + disabled_checks.map{ |check| "--no-#{check}-check" } + ['-f', '.']
    sh runcmd.join(' ')
  end

  desc 'Cleanup'
  task :clean do
    sh 'rm -rf puppet/pkg'
  end


  desc 'Build Puppet module'
  task :build do
    sh 'puppet module build --verbose puppet'
    sh 'cp -rv puppet/pkg/*.gz ./'
    Rake::Task['puppet:clean'].invoke
  end

  desc 'Clean & build'
  task :all => [:clean, :build]
end

namespace :gem do
  desc 'Build gem'
  task :build do
    sh 'cd gem && gem build -V port-authority.gemspec'
  end

  desc 'Install local gem'
  task :install do
    sh 'gem install gem/port-authority-*.gem'
  end

  desc 'Clean build gems'
  task :clean do
    sh 'rm -f gem/*.gem'
  end

  desc 'Push new gem'
  task :push do
    sh 'gem push gem/port-authority-*.gem'
  end

  desc 'Clean, build & install'
  task all: [:clean, :build, :install]
end
