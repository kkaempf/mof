require 'bundler/gem_tasks'
require 'rake/testtask'

Dir['tasks/**/*.rake'].each { |t| load t }

task :default => [:test]

task :racc do
  sh %{racc -o lib/mof/parser.rb lib/mof/parser.y}
end
