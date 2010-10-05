rule '.rb' => '.y' do |t|
   sh "racc -g -v -o #{t.name} #{t.source}"
end

task :test => [:build]

built_files = ["lib/mof/parser.rb", "lib/mof/parser.output"]
task :build => built_files

task :clean => [:clean_built]

task :clean_built do
  built_files.each do |f|
    File.delete f
  end
end
