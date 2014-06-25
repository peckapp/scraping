require 'mechanize'
require 'nokogiri'
require 'feedjira'
require 'uri'
require 'bloomfilter-rb'
require 'logger'
require 'timeout'

class Crawler

  attr_reader :pages_crawled

  def initialize(root_url, timeout=8, page_quantity=15000, bf_bits=15)
    @agent = Mechanize.new{|a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}
    @agent.read_timeout = timeout
    @agent.open_timeout = timeout

    @crawl_queue = Array.new # using an array to prevent special threading features of actual queues in ruby that block

    k = (0.7 * bf_bits).ceil
    @bf = BloomFilter::Native.new(size: page_quantity, hashes: k, seed: 1)

    @root_url = root_url

    # puts the starting seed page in the queue
    root_page = @agent.get(@root_url)
    @crawl_queue.insert(0,root_page)

    @pages_crawled = 0 # incremented for every iteration of the main crawl loop
  end

  def crawl_loop

    logger = Logger.new('logfile.log')
    logger.level = Logger::DEBUG

    logger.debug("Created logger")
    logger.info("Program started")
    logger.warn("Nothing to do!")


    while ! @crawl_queue.empty? do
      page = @crawl_queue.pop

      if page.kind_of? Mechanize::Image
        puts "Image in crawl queue for uri: #{page.uri}"
      end

      next unless page.kind_of? Mechanize::Page

      @pages_crawled += 1

      logger.info "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
      logger.info "queue contains: #{@crawl_queue.count.to_s} with #{@pages_crawled} scraped so far"
      logger.info "Starting page: " + page.title.to_s
      logger.info "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"

      links_inspected = 0

      page.links.each do |l|

        links_inspected += 1
        STDOUT.write "\rqueue contains: #{@crawl_queue.count.to_s} with #{@pages_crawled} scraped so far and #{links_inspected} links inspected for the current page"

        # utilizes a bloom filter to keep track of links that have already been traversed
        if @bf.include?(l.href.to_s) then
          # puts "HREF: #{l.href} already added to queue"
          next
        end
        @bf.insert(l.href.to_s)

        next unless Crawler.acceptable_link_format?(l)

        logger.info "added HREF: #{l.href}"

        next unless within_domain?(l.uri)

        logger.info "above was within domain"

        begin
          new_page = l.click
          @crawl_queue.insert(0,new_page)
        rescue Timeout::Error
          logger.warn "TIMEOUT for HREF: #{l.href}"
        rescue Mechanize::ResponseCodeError => exception
          if exception.response_code == '403'
            new_page = exception.page
          else
            raise # Some other error, re-raise
          end
        end

        # passes the current page to a block so that it can be appropriately processed
        yield new_page

        sleep + (1.0 * rand)

      end
    end
    logger.close
  end

  def self.acceptable_link_format?(link)
    begin
      if link.uri.to_s.match(/#/) || link.uri.to_s.empty? then return false end # handles anchor links within the page
      scheme = link.uri.scheme
      if (scheme != nil) && (scheme != "http") && (scheme != "https") then return false end # eliminates non http,https, or relative links
      # prevents download of media files, should be a better way to do this than by explicit checks for each type
      if link.uri.to_s.match(/.pdf|.jgp|.jgp2|.png|.gif/) then return false end
    rescue
      return false
    end
    true
  end

  def within_domain?(link)
    if link.relative?
      true # handles relative links within the site
    else
      # matches the current links host with the top-level domain string of the root URI
      link.host.match(@root_host.to_s) ? true : false
    end
  end

end


if __FILE__ == $0
  # starts the loop crawling the website

  rss_block = lambda { |page|
    next unless page.uri.to_s.match(/rss/)
    puts "RSS"
    logger.info "********************************"
    logger.info "RSS: " + page.uri.to_s
    logger.info "********************************"
    @rss_feeds << page.uri
    # spawn a new thread to parse the rss feed site
    rss_scrape = Thread.new {
      crawler.scrape_uri(page.uri.to_s)
    }
  }

  root = ARGV[1] ? ARGV[1] : "http://www.williams.edu"

  begin
    puts "running crawler with root: #{root}"
    crawler = Crawler.new(root)
    crawler.crawl_loop &rss_block
  rescue Interrupt
    puts "\nended crawl"
  ensure
    puts "#{crawler.pages_crawled} pages traversed"
  end
end
