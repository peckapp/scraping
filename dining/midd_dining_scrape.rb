require 'restclient'
require 'nokogiri'
require 'watir-webdriver'

require 'active_support/core_ext/date'

# require 'headless'
# headless = Headless.new
# headless.start

MIDD_MENUS = "http://menus.middlebury.edu"

MIDD_DATE_FORMAT = "%A, %B %-d, %Y"


def self.menu_loop(b)
  (0..30).each do |increment|

    puts "#{increment} days from now"

    date = Date.current + increment
    date_str = date.strftime(MIDD_DATE_FORMAT)

    date_field = b.text_field name: 'field_day_value[value][date]'

    date_field.set date_str

    apply_button = b.button id: 'edit-submit-menus-test'

    apply_button.click

    data = b.div :class => 'view view-menus-test view-id-menus_test view-display-id-page view-dom-id-163dd5c9ac75a8917cab3b5b23c99f07 jquery-once-1-processed'

    self.scrape_html(data.html)

    sleep 1 + rand

  end
end


def self.scrape_html(html_raw)
  html = Nokogiri::HTML(html_raw)

  puts 'will be scraping'

end


begin
  b = Watir::Browser.new
  b.goto MIDD_MENUS
  puts 'entering loop'
  self.menu_loop(b)
rescue
  raise
ensure

  puts 'closing'

  b.close
  # headless.destroy
end
