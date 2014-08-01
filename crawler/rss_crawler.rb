require 'mechanize'
require 'nokogiri'
require 'feedjira'
require 'uri'
require 'bloomfilter-rb'
require 'logger'
require 'timeout'

# Experimental crawler that traverses a site and prints out a parsed form of the RSS feeds

class RSSCrawler
  # no verification because it failed on some pages and it isn't necessary for crawling.
  # vulnerabilites can only be present here if a link from the institution site points to a somehow malicious rss feed
  @agent = Mechanize.new { |a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE }
  @agent.read_timeout = 8
  @agent.open_timeout = 8

  @crawl_queue = [] # using an array to prevent special threading features of actual queues in ruby
  # m = 150,000, k = 11, seed = 666
  @bf = BloomFilter::Native.new(size: 150_000, hashes: 11, seed: 1)
  @pages_crawled = 0
  @rss_feeds = []

  @root_url = ARGV[0] ? ARGV[0] : 'http://www.williams.edu' # command line input or default of williams website
  @root_uri = URI.parse(@root_url)
  puts "root_url: #{@root_url} root_uri: #{@root_uri}"
  @root_host = @root_uri.host.slice(@root_uri.host.index('.') + 1..@root_uri.host.length)

  root_page = @agent.get(@root_url)
  @crawl_queue.insert(0, root_page) # inserts root into the crawl queue to start the process
  @bf.insert(root_page.link.href.to_s) # inserts root into the Bloomfilter to prevent repeated crawling

  def self.crawl_loop
    puts 'Program started'

    logger = Logger.new("rss_log_#{ARGV[1]}.log")
    logger.level = Logger::INFO

    until @crawl_queue.empty?
      page = @crawl_queue.pop

      if page.is_a? Mechanize::Image
        puts "Image in crawl queue for uri: #{page.uri}"
      end

      next unless page.is_a? Mechanize::Page

      @pages_crawled += 1

      puts "\n\n||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
      puts "queue contains: #{@crawl_queue.count} with #{@pages_crawled} scraped so far"
      puts "page: #{page.title.to_s.strip} at #{page.uri} with #{page.links.count} links"
      puts "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||\n\n"

      page.links.each do |l|

        # utilizes a bloom filter to keep track of links that have already been traversed
        if @bf.include?(l.href.to_s) then
          # puts "HREF: #{l.href} already added to queue"
          next
        end
        @bf.insert(l.href.to_s)
        puts "HREF: #{l.href}"

        next unless self.acceptable_link_format?(l)

        # puts "#{l.uri.class} is relative? #{l.uri.relative?}"
        uri = l.uri

        if self.rss?(uri)
          puts '********************************'
          puts "RSS: #{uri}"
          puts '********************************'
          logger.info "RSS: #{uri}"
          @rss_feeds << uri
          # spawn a new thread to parse the rss feed site
          rss_scrape = Thread.new {
            scrape_uri(uri.to_s)
          }
        end

        next unless self.within_domain?(uri)

        puts 'ADDED TO QUEUE ^^^^^^^^^^^^^^^^^^^'

        begin
          new_page = l.click
          @crawl_queue.insert(0, new_page)
        rescue Timeout::Error
          logger.warn "TIMEOUT for HREF: #{l.href}"
          puts 'TIMEOUT FOR ABOVE ^^^^^^^^^^^^^^'
        rescue Mechanize::ResponseCodeError => exception
          if exception.response_code == '403'
            new_page = exception.page
          else
            logger.error "exception: #{exception} returned for uri: #{uri}" # Some other error, re-raise
          end
        end

        sleep (1.0 * rand)

      end
    end
  end

  # scrapes a given rss feed indicated by the string passed in of its uri
  def self.scrape_uri(uri)
    feed = Feedjira::Feed.fetch_and_parse(uri)

    feed.entries.each { |entry|
      entry_h = {}
      entry_h[:title] = entry.title
      entry_h[:url] = entry.url
      html = Nokogiri::HTML(entry.summary)
      entry_h[:summary] = {}
      html.xpath('//b').each { |t|
        val = t.next.text.match(/[[:alnum:]]/) ? t.next : t.next.next
        entry_h[:summary][t.text] = val.text
      }
      # replace this with a write to a seperate file
      puts "\n#{entry_h}"
    }
  end

  def self.acceptable_link_format?(link)
    begin
      if link.uri.to_s.match(/#/) || link.uri.to_s.empty? then return false end # handles anchor links within the page
      scheme = link.uri.scheme
      if (!scheme.nil?) && (scheme != 'http') && (scheme != 'https') then return false end # eliminates non http,https, or relative links
      # prevents download of media files, should be a better way to do this than by explicit checks for each type
      if link.uri.to_s.match(/.pdf|.jgp|.jgp2|.png|.gif/) then return false end
    rescue
      return false
    end
    true
  end

  def self.within_domain?(link)
    if link.relative?
      puts 'link is relative'
      true # handles relative links within the site
    else
      # matches the current links host with the top-level domain string of the root URI
      result = link.host.match(@root_host.to_s) ? true : false
      puts "#{link.host} matches #{@root_host} with result #{result}"
      result
    end
  end

  def self.rss?(link)
    link.to_s.match(/rss/)
  end

  if __FILE__ == $PROGRAM_NAME

    # starts the loop crawling the website
    begin
      puts 'running RSS crawler'
      crawl_loop
    rescue Interrupt
      puts "\nended crawl"
    ensure
      puts "#{@rss_feeds.count} RSS feeds found"
      @rss_feeds.each { |feed| puts feed.to_s }
    end
  end
end
