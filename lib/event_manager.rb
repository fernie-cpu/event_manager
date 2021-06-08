require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/, '')
  if phone_number.length == 10
    phone_number
  elsif phone_number[0] == "1" && phone_number.length == 11
    phone_number[1..10]
  else
    puts "bad number"
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

def open_csv
  CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end


puts 'EventManager Initialized!'
puts ""

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def find_hour
  contents = open_csv
  reg_hour_arr = Array.new
  hour_hash = Hash.new(0)

  contents.each do |row|
    reg_date = row[:regdate]
    reg_hour = Time.strptime(reg_date, '%M/%d/%y %k:%M').strftime('%k')
    reg_hour_arr.push(reg_hour)
  end

  reg_hour_arr.reduce(hour_hash) do |hour_hash, h|
    hour_hash[h] += 1
    hour_hash
  end

  hour_hash.each { |k, v| puts "Most common hour for registration was #{k}:00" if v == hour_hash.values.max }
end

def find_day
  contents = open_csv
  reg_day_arr = Array.new
  day_hash = Hash.new(0)

  contents.each do |row|
    reg_date = row[:regdate]
    reg_day = Time.strptime(reg_date, '%M/%d/%y %k:%M').strftime('%A')
    reg_day_arr.push(reg_day)
  end

  reg_day_arr.reduce(day_hash) do |day_hash, h|
    day_hash[h] += 1
    day_hash
  end

  day_hash.each { |k, v| puts "Most common day for registration was #{k}" if v == day_hash.values.max }
end

contents = open_csv
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  home_phone = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id, form_letter)

  puts "#{name} #{zipcode} #{home_phone}"
end

find_hour
find_day