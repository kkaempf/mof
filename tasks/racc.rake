rule '.rb' => '.y' do |t|
   sh "racc -g -v -o #{t.name} #{t.source}"
end

task :test => [:racc]
task :build => [:racc]

task :racc => ["lib/mof/parser.rb"]
