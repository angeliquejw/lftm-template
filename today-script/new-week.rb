# ruby today-script/new-week.rb
# Creates a weekly journal file based on the format in the template file

require 'date'

# Create a new journal file
template = 'journal/00000000.md'
wkdir = 'journal/work/'
date = (Date.today) # Note that this currently assumes the file is created at the start of the week 🤷🏻‍♀️
file_date = date.strftime('%m%d%Y')
file_name = wkdir + file_date + '.md'

system("cp -i #{template} #{file_name}")

# Replace the header from the template
header_date = date.strftime('%m.%d.%Y')
new_heading = "Week of #{header_date}"

File.open(file_name, 'r+') do |f|
  f.write new_heading
end

system("code #{file_name}")
