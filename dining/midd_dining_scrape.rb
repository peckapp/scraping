require 'restclient'
require 'nokogiri'
require 'watir-webdriver'

require 'active_support/core_ext/date'
require 'active_support/core_ext/string/filters'

# require 'headless'
# headless = Headless.new
# headless.start

MIDD_MENUS = 'http://menus.middlebury.edu'

MIDD_DATE_FORMAT = '%A, %B %-d, %Y'

def self.menu_loop(b)
  (0..5).each do |increment|

    puts "#{increment} days from now"

    date = Date.current + increment
    date_str = date.strftime(MIDD_DATE_FORMAT)

    date_field = b.text_field name: 'field_day_value[value][date]'

    date_field.set date_str

    apply_button = b.button id: 'edit-submit-menus-test'

    apply_button.click

    data = b.div class: 'view view-menus-test view-id-menus_test view-display-id-page'

    if data.exists?

      html_raw = data.html

      scrape_html(data.html.squish, date)

    else
      puts "couldn't find data!!!"
    end

    sleep 1 + rand

  end
end

def self.scrape_html(html_raw, date)
  html = Nokogiri::HTML(html_raw)

  puts 'scraping'

  html.css("table[class*='views-view-grid']").each do |table|

    place = table.previous.previous.text

    table.css('td').each do |entry|
      opportunity_type = entry.css('span[class=field-content]').text

      entry.css('p').children.each do |item|
        unless item.text.blank?

          item_name = item.text

          mi = { item_name: item_name, opportunity_type: opportunity_type, place: place, date: date }

          puts mi

        end # end if
      end # end entry items

    end # end table entries

  end # end tables
end

begin
  b = Watir::Browser.new
  b.goto MIDD_MENUS
  puts 'entering loop'
  menu_loop(b)
rescue
  raise
ensure

  puts 'closing'

  b.close
  # headless.destroy
end
