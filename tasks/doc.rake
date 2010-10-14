task :doc do
  `rm -rf doc`
  `rdoc -c utf-8 lib`
end