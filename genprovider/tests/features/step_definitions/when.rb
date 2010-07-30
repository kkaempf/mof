When /^I run genprovider with no arguments$/ do
  @output = `ruby #{GENPROVIDER} 2> stderr.out`
end

When /^I pass "([^"]*)" to genprovider redirecting its output to "([^"]*)"$/ do |arg1, arg2|
  IO.popen("ruby #{GENPROVIDER} -o #{arg2} #{File.join(MOFDIR, arg1)} > stdout.out 2> stderr.out")
end

When /^I pass "([^"]*)" to genprovider$/ do |arg1| #"
  @output = `ruby #{GENPROVIDER} #{File.join(MOFDIR, arg1)} 2> stderr.out`
end

