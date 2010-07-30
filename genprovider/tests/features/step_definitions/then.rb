Then /^I should see a short usage explanation$/ do
  @output =~ /Usage:/
end

Then /^I should see an "([^"]*)" file$/ do |arg1| #"
  File.exists? arg1
end

Then /^comment lines should not exceed "([^"]*)" characters$/ do |arg1| #"
  maxcolumn = arg1.to_i
  @output.scan(/^\s*\#.*$/).each do |l|
    return false if l.chomp.size > maxcolumn
  end
  true
end