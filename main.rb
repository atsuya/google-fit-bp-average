require 'date'
require 'json'
require 'net/http'

if ARGV.size != 2
  puts 'Usage: ruby main.rb <START_DATE_EPOCH> <END_DATE_EPOCH>'
  puts 'Example: ruby main.rb 2021-01-20 2021-02-20'
  exit 1
end

unless ENV['GOOGLE_ACCESS_TOKEN']
  puts 'Make sure to set GOOGLE_ACCESS_TOKEN environment variable to access token'
  exit 1
end

# the api requires the time to be in nanoseconds
start_time_raw = ARGV[0]
end_time_raw = ARGV[1]
start_time = DateTime.parse(start_time_raw).to_time.to_i * 1000000000
end_time = DateTime.parse(end_time_raw).to_time.to_i * 1000000000

api_endpoint = 'https://www.googleapis.com/fitness/v1/users/me/dataSources/derived:com.google.blood_pressure:com.google.android.gms:merged/datasets/%d-%d' % [start_time, end_time]

api_endpoint_uri = URI(api_endpoint)
request = Net::HTTP::Get.new(api_endpoint_uri)
request['Authorization'] = 'Bearer %s' % ENV['GOOGLE_ACCESS_TOKEN']

response = Net::HTTP.start(api_endpoint_uri.hostname, api_endpoint_uri.port, :use_ssl => true) { |http| http.request(request) }
status_code = response.code.to_i
unless status_code >= 200 && status_code < 300
  puts 'The API returned non-2xx status code, aborting'
  exit 2
end

blood_pressure_entries = []
data = JSON.parse(response.body)
data['point'].each do |point|
  measured_at = Time.at((point['startTimeNanos'].to_i / 1000000000), in: 'UTC')
  systolic = point['value'][0]['fpVal']
  diastolic = point['value'][1]['fpVal']
  blood_pressure_entries << {
    :measured_at => measured_at,
    :systolic => systolic,
    :diastolic => diastolic
  }

  #puts '%s,%02f,%02f' % [measured_at.localtime.to_s, systolic, diastolic]
end

# average
total_systolic = blood_pressure_entries.reduce(0) { |sum, entry| sum + entry[:systolic] }
average_systolic = total_systolic / blood_pressure_entries.size.to_f

total_diastolic = blood_pressure_entries.reduce(0) { |sum, entry| sum + entry[:diastolic] }
average_diastolic = total_diastolic / blood_pressure_entries.size.to_f

# max
max_systolic = blood_pressure_entries.max { |a, b| a[:systolic] <=> b[:systolic] }[:systolic]
max_diastolic = blood_pressure_entries.max { |a, b| a[:diastolic] <=> b[:diastolic] }[:diastolic]

# min
min_systolic = blood_pressure_entries.min { |a, b| a[:systolic] <=> b[:systolic] }[:systolic]
min_diastolic = blood_pressure_entries.min { |a, b| a[:diastolic] <=> b[:diastolic] }[:diastolic]

puts '========================================'
puts '==               Result               =='
puts '========================================'
puts 'Period: %s - %s' % [start_time_raw, end_time_raw]
puts 'Total entries: %d' % blood_pressure_entries.size
puts ''
puts 'Systolic: max=%d, min=%d, average=%.2f' % [max_systolic, min_systolic, average_systolic]
puts 'Diastolic: max=%d, min=%d, average=%.2f' % [max_diastolic, min_diastolic, average_diastolic]
