require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def parse_phone(phone)
  if phone.count == 10
    phone.join
  elsif phone.count < 10
    false
  elsif phone.count > 10
    if phone[0] == 1.to_s
      phone[1..-1].join
    else
      false
    end
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

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

times = []
days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  phone = row[:homephone].gsub(/\D/, "").chars
  parse_phone(phone)
  save_thank_you_letter(id,form_letter)
  time = row[:regdate]
  time = DateTime.strptime(time, '%m/%d/%y %H:%M')
  formatted = time.strftime("%I %p")
  times << formatted
  days << time.strftime("%A")
end

def common_times(times)
  hash = Hash.new(0)
  times.each do |time| 
    hash[time] += 1
  end
  hash.each{|k,v| if v > 1 then puts "#{k} - #{v} registrations" end}
end

def common_days(days)
  hash = Hash.new(0)
  days.each do |day| 
    hash[day] += 1
  end
  hash.each{|k,v| if v > 0 then puts "#{k} - #{v} registrations" end}
end

common_days(days)
common_times(times)
