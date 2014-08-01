require 'nokogiri'
require 'restclient'
require 'diffy'

demo_url = 'https://events.williams.edu/widget/view?schools=williams&days=30&num=5&format=rss'
raw = RestClient::Request.execute(url: demo_url, method: :get, verify_ssl: false)

html = Nokogiri::XML(raw)

html_raw = html.to_html

puts Diffy::Diff.new(raw, html_raw)
