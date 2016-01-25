#!/usr/bin/env ruby

require 'puppet'
require 'puppet-lint'
require 'time'
require 'open3'

class PuppetTester
  def initialize(path='modules',disabled_checks=[])
    @t_start = Time.now.to_f
    @path = path.sub(/\/$/, '')
    @modules = Dir[@path + '/*'].select{|f| File.directory? f}.sort
    @pe = Puppet.lookup(:current_environment)
    @erb_bin = `/bin/which erb`.sub(/\n$/, '')
    @ruby_bin = `/bin/which ruby`.sub(/\n$/, '')
    if Puppet.version < '4.0.0'
      Puppet[:parser] = 'future'
      Puppet[:evaluator] = 'future'
    end
    disabled_checks.each do |check|
      PuppetLint.configuration.check_object.delete check.to_sym
    end
    puts purple("Ruby version:\t\t" + RUBY_VERSION)
    puts purple("Puppet version:\t\t" + Puppet.version)
    puts purple("Puppet lint version:\t" + Gem.loaded_specs['puppet-lint'].version.to_s)
  end

  def red(text)
    "\e[31m" + text + "\e[0m"
  end

  def green(text)
    "\e[32m" + text + "\e[0m"
  end

  def yellow(text)
    "\e[33m" + text + "\e[0m"
  end

  def purple(text)
    "\e[35m" + text + "\e[0m"
  end

  def cyan(text)
    "\e[36m" + text + "\e[0m"
  end

  def parser_validate(mod)
    Dir[mod + '/**/*.pp'].each do |pp|
      $stdout.print "  #{cyan('PARSER')} #{pp}: "
      begin
        validation_environment = pp ? @pe.override_with(manifest: pp) : @pe
        validation_environment.check_for_reparse if Puppet.version >= '4.0.0'
        validation_environment.known_resource_types.clear
        puts green('OK')
      rescue => e
        (msg, coords) = e.message.sub(/^.*: (.*) at \/.*:([0-9\:]{3,})$/, "\\1|||\\2").split('|||')
        puts red('FAILED')
        puts red('==> ERROR') + " [#{coords}] #{msg}"
        return false
      end
    end
    return true
  end

  def erb_validate(mod)
    Dir[mod + '/templates/**/*'].delete_if{ |f| File.directory? f }.each do |erb|
      $stdout.print "  #{cyan('ERB   ')} #{erb}: "
      erb_contents = File.open erb
      cmd = [ @erb_bin, '-T', "'-'", '-x', '-', '|', @ruby_bin, '-c' ].join(' ')
      errors = []
      output = []
      Open3.popen3(cmd) do |stdin,stdout,stderr|
        stdin.puts erb_contents
        stdin.close
        errors += stderr.read.split('\n')
        output += stdout.read.split('\n')
      end
      if errors.length == 0 && output.first =~ /Syntax OK/ then
        puts green('OK')
      else
        puts red('FAILED')
        errors.each do |error|
          puts red('==> ERROR') + " #{error}"
        end
        output.each do |line|
          puts yellow('    ERROR') + " #{line}"
        end
        return false
      end
    end
    return true
  end

  def lint(mod)
    Dir[mod + '/**/*.pp'].each do |pp|
      $stdout.print "  #{cyan('LINTER')} #{pp}: "
      lint = PuppetLint.new
      lint.file = pp
      lint.run
      lint.problems.length >= 1 ? puts(red('FAILED')) : puts(green('OK'))
      lint.problems.each do |problem|
        case problem[:kind].to_s
        when 'warning'
          puts yellow("    #{problem[:kind].upcase}") + " [#{problem[:line]}:#{problem[:column]}] #{problem[:message]}"
        when 'error'
          puts red("==> #{problem[:kind].upcase}") + " [#{problem[:line]}:#{problem[:column]}] #{problem[:message]}"
        end
      end
      if lint.problems.delete_if{ |problem| problem[:kind].to_s == 'warning' }.length > 0 then
        return false
      end
    end
    return true
  end

  def result result
    puts
    if result
      text = green('SUCCESS')
      code = 0
    else
      text = red('FAILURE')
      code = 1
    end
    @t_end = Time.now.to_f
    duration = sprintf('%.3f seconds', @t_end - @t_start)
    puts purple "Result: #{text}"
    puts purple "Duration: #{duration}"
    exit code
  end

  def run
    r = true
    @modules.each do |mod|
      puts purple("\nTesting module '#{mod.split('/')[1]}'")
      parser_validate(mod) || ( r = false; break )
      erb_validate(mod)    || ( r = false; break )
      lint(mod)            || ( r = false; break )
    end
    result r
  end
end
