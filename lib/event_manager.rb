require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phonenumber(homephone)
    homephone = homephone.delete('^0-9').to_s #extracts numbers from string

  if homephone.length == 10 
    return homephone
  end
  if homephone.length == 11
    if homephone[0] == "1"
      return homephone = homephone[1..11]
    else false
    end
  end
end

def frequent_time(regtime)
  hours = Array.new
  regtime.each do
    |time|
     parsed_time = time[time.index(' ')+1..-1]
  date = Time.parse(parsed_time)
  hours.push(date.hour)
  end
  return hours.group_by { |n| n }.values.max_by(&:size).first #Prints most frequent hour

end

def frequent_date(regdate)
  dates = Array.new
  
  regdate.each do
    |date|
    dates.push(Date.strptime(date, '%D').wday) 
  end

  day = dates.group_by { |n| n }.values.max_by(&:size).first #Prints most frequent day of week (0-6, Sunday is zero).
  
  if day = 0
    return "Sunday"
  elsif day == 1
    return "Monday"
  elsif day == 2
    return "Tuesday"
  elsif day == 3
    return "Wednesday"
  elsif day == 4
    return "Thursday"
  elsif day == 5
    return "Friday"
  elsif day == 6
    return "Saturday"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def save_registration_analysis(regdate, regtime)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/registration_analysis.txt"

  File.open(filename, 'w') do |file|
    file.puts "The most common date was #{regdate} and the most common hour was #{regtime}:00."
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

regtime = Array.new
regdate = Array.new

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  homephone = clean_phonenumber(row[:homephone])
  regtime.push(row[:regdate])
  regdate.push(row[:regdate])

  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

frequent_hour = frequent_time(regtime)
frequent_day = frequent_date(regdate)

save_registration_analysis(frequent_day, frequent_hour)
