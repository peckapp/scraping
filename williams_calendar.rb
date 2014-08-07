require 'restclient'
require 'nokogiri'
require 'watir-webdriver'

@url = 'https://events.williams.edu/calendar/month/2014/8'

def retrieve_html
  raw = RestClient::Request.execute(url: @url, method: :get, verify_ssl: false)
  Nokogiri::HTML(raw)
end

def iterate_html
  puts 'iterating'
  html = retrieve_html
  html.css('.summary a').each do |title|
    unless title.class == Nokogiri::XML::Element
      puts 'anamolous title with multiple elements' if title.count > 1
      title = title.first
    end
    puts "title: #{title}"
    link = title.attributes['href']
    puts "link: #{link}"
  end
end

iterate_html
