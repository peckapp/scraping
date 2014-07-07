require 'nokogiri'
require 'feedjira'

# a class that parses rss feeds into the appropriate format for the database using the feedjira library

class RssParser
  
  def initialize(url)
    @url = url
  end

end
