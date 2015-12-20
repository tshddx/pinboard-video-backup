require 'rss'
require 'logger'

class PinboardVideoBackup
  BACKED_UP_URLS_FILE = "backed_up_urls.txt"
  LOG_FILE = "log.log"

  attr_accessor :username
  attr_accessor :logger
  attr_accessor :backed_up_urls
  attr_accessor :backed_up_urls_file
  
  def initialize(username)
    self.username = username
    self.logger = Logger.new(LOG_FILE, "daily")
    self.backed_up_urls_file = File.open(BACKED_UP_URLS_FILE, "a+")
    self.backed_up_urls = backed_up_urls_file.read.lines.map(&:strip).to_set
  end

  def backup
    urls = urls_from_rss
    length = urls.length
    
    urls.each.with_index do |url, i|
      if backed_up_urls.include?(url)
        puts "-- Already backed up #{url} --"
        next
      end
      
      logger.info("Calling youtube-dl (#{i + 1} of #{length}) #{url}")
      `youtube-dl -citw --quiet --no-warnings --write-info-json #{url}`
      backed_up_urls_file.puts(url)
    end

    backed_up_urls_file.close
    logger.info("Backup complete")
  rescue => e
    logger.fatal("Error in backup method: #{e}")
    backed_up_urls_file.close
  end

  def rss_url
    "https://feeds.pinboard.in/rss/u:#{username}"
  end

  def urls_from_rss
    begin
      logger.info("Requesting RSS feed #{rss_url}")
      rss = RSS::Parser.parse(rss_url)
      logger.info("RSS contains #{rss.items.length} items")
      return rss.items.map(&:link)
    rescue => e
      logger.error(e)
      return []
    end
  end
end
