require 'restclient'
require 'nokogiri'
require 'watir-webdriver'

require 'active_support/core_ext/date'
require 'active_support/core_ext/string/filters'

@url = 'https://events.williams.edu/calendar/'

def retrieve_html(url)
  raw = RestClient::Request.execute(url: url, method: :get, verify_ssl: false)
  Nokogiri::HTML(raw.squish)
end

def parse_page(url)
  html = retrieve_html(url)

end

def iterate_html
  puts 'iterating'
  html = retrieve_html(@url)
  html.css('.summary a').each do |title|
    unless title.class == Nokogiri::XML::Element
      puts 'anamolous title with multiple elements' if title.count > 1
      title = title.first
    end
    link = title.attributes['href']
    parse_page(link)
  end
end

iterate_html
