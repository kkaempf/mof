rule '.rb' => '.y' do |t|
   sh "racc -g -v -o #{t.name} #{t.source}"
end

#clean:
#	$(RM) mofparser.rb
#	$(RM) mofparser.output

