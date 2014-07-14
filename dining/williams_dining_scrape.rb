# script to scrape the williams dining menus from the csv file outputted daily

require 'restclient'
require 'csv'


CSV_URL = "http://dining.williams.edu/files/daily-menu.csv"

file = RestClient.get(CSV_URL)

csv = CSV.parse(file)

csv.each do |l|
  puts l
end
