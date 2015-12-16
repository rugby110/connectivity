#!/usr/bin/env ruby
require 'logger'
require 'timeout'

module ConnectivitySuite
  # input for the runner method
  module Data


    def self.webhosts
      HOSTS.keys
    end

    def self.domain_path
      HOSTS.map { |k, v| k + v }
    end

    HOSTS = {
      'soundcloud.com' => '/robots.txt',
      'api-v2.soundcloud.com' => '/robots.txt',
      'ec-media.sndcdn.com' => '/crossdomain.xml',
      'a-v2.sndcdn.com' => '/robots.txt',
      'api.soundcloud.com' => '/robots.txt',
      'cf-media.sndcdn.com' => '/robots.txt',
      'eventgateway.soundcloud.com' => '/robots.txt',
      'i1.sndcdn.com' => '/robots.txt',
      'i2.sndcdn.com' => '/robots.txt',
      'i3.sndcdn.com' => '/robots.txt',
      'i4.sndcdn.com' => '/robots.txt',
      'promoted.soundcloud.com' => '/robots.txt',
      'va.sndcdn.com' => '/robots.txt',
      'wis.sndcdn.com' => '/robots.txt'
    }

    INPUT = "\n
              time_namelookup:  %{time_namelookup}\n
                 time_connect:  %{time_connect}\n
              time_appconnect:  %{time_appconnect}\n
             time_pretransfer:  %{time_pretransfer}\n
                time_redirect:  %{time_redirect}\n
           time_starttransfer:  %{time_starttransfer}\n
                              ----------\n
                   time_total:  %{time_total}\n\n"
  end

  module Features
    class NoIPError < StandardError; end
    class HostChecker
      def initialize(host, logger = Logger.new($stdout))
        @host = host
        @logger = logger
        @logger.info("Checking host '#{@host}'")
      end

      attr_reader :host
    
      def ip
        return @ip if @ip
        time = Time.now
        @ip = (`dig +short #{@host}`).split(' ').last.scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/).first
        unless @ip
          @logger.warn("Resolve '#{@host}' to IP failed - #{'%.5f' % (Time.now - time)} sec")
          raise NoIPError, "IP resolution failed"
        else
          @logger.debug("Resolve '#{@host}' to IP #{@ip} - #{'%.5f' % (Time.now - time)} sec")
          @ip
        end
      end

      def ping 
        time = Time.now
        begin
          output = (`ping -c5 #{ip} 2>/dev/null`)
          @logger.debug("'#{@host}' is pinged - #{'%.5f' % (Time.now - time)} sec")
          output
        rescue NoIPError => e
          @logger.warn("Skipped ping for '#{@host}': #{e.message} - #{'%.5f' % (Time.now - time)} sec")
          raise e
        rescue Exception => d
          @logger.warn("Skipped Ping for #{@host}: #{d.message}")
          raise e
        end
      end

      def valid_ip?
        begin
          time = Time.now
          ping_output = ping
          output = zero_packets_lost?(ping_output) && within_timeout?(ping_output)
          result = output ? true : false
          @logger.info("For '#{@host}' IP connection  => #{result} - #{'%.5f' % (Time.now - time)} sec")
          result
        rescue NoIPError => e
          @logger.warn("Skipped IP validation for '#{@host}': #{e.message} - #{'%.5f' % (Time.now - time)} sec")
           false
        end
      end

      def zero_packets_lost?(ping_output)
        begin
          time = Time.now
          percentage_lines = ping_output.split("\n").detect { |x| x.include?('%') }.split(' ').detect { |x| x.include?('%') } 
          result = percentage_lines == '0.0%' || percentage_lines == '0%'
          @logger.info("For '#{@host}' 0.0% package loss  => #{result} - #{'%.5f' % (Time.now - time)} sec")
          result
        rescue NoIPError => e
          @logger.warn("Skipped Packet loss for '#{@host}': #{e.message} - #{'%.5f' % (Time.now - time)} sec")
          false
        rescue
          @logger.warn("Skipped Packet loss for '#{@host}' - #{'%.5f' % (Time.now - time)} sec")
          false
        end
      end

      def within_timeout?(ping_output)
        begin
          time = Time.now
          output = ping_output
          avg = output.split("\n").grep(/avg/).first.split(' ')[3].split('/')[2].to_i <= 300
          result = avg ? true : false
          @logger.info("For '#{@host}' avg round-trip < 300 ms  => #{result} - #{'%.5f' % (Time.now - time)} sec")
          output
        rescue
          @logger.warn("BLOCKER: within_timeout nil for '#{@host}'")
          false
        end
      end

      def whois
        time = Time.now
        if (`which whois > /dev/null; echo $?`).to_i.zero?
          begin
            if (`whois #{ip}; echo $?`).to_i.zero?
              who = (`whois #{ip}`)
              @logger.debug("Obtain NICs databases records for hostname '#{@host}' - #{'%.5f' % (Time.now - time)} sec")
              who
            end
          rescue NoIPError => e
            @logger.warn("Skipped whois request for '#{@host}': #{e.message}")
            raise e
          end
        else
          puts 'if you run this script on linux please install whois on your machine'
          nil
        end
      end

      def get(url)
        if (`which curl > /dev/null; echo $?`).to_i.zero?
            `curl -m 10 '#{url}' 2> /dev/null`
        else
          `wget -q -O - '#{url}' 2> /dev/null`
        end
      end

      def edgecast?
        begin
          time = Time.now
          output = get("https://wq.apnic.net/whois-search/query?searchtext=#{ip}").include?("EDGECAST")
          result = output ? true : false
          @logger.info("CDN Edgecast for '#{@host}' => #{result} - #{'%.5f' % (Time.now - time)} sec")
          output
        rescue NoIPError => e 
          @logger.warn("Skipped Edgecast-Check for '#{@host}': #{e.message} - #{'%.5f' % (Time.now - time)} sec")
          raise e
        end
      end

      def cloudfront?
        begin
          time = Time.now
          if (`which curl > /dev/null; echo $?`).to_i.zero?
            whois = `curl 'https://wq.apnic.net/whois-search/query?searchtext=#{ip}' 2> /dev/null`
            output = whois.include?('Amazon Technologies')
            result = output ? true : false
            @logger.info("CDN Cloudfront for '#{@host}' => #{result} - #{'%.5f' % (Time.now - time)} sec")
            output
          else
            whois = `wget -q -O -  'https://wq.apnic.net/whois-search/query?searchtext=#{ip}' 2> /dev/null`
            output = whois.include?('Amazon Technologies')
            result = output ? true : false
            @logger.info("CDN Cloudfront for '#{@host}' with wget => #{result} - #{'%.5f' % (Time.now - time)} sec")
            output
          end
        rescue NoIPError => e 
          @logger.warn("Skipped Cloudfront-Check for '#{@host}': #{e.message} - #{'%.5f' % (Time.now - time)} sec")
          raise e
        end
      end

      def valid_dns?
        begin
          time = Time.now
          valid = edgecast? || cloudfront?
          @logger.info("Valid DNS for #{@host} => #{valid} - #{'%.5f' % (Time.now - time)} sec")
          valid
        rescue NoIPError => e 
          @logger.warn("Skipped DNS validation for #{@host}: #{e.message} - #{'%.5f' % (Time.now - time)} sec")
          false
        end
      end

      def traceroute
        begin
        time = Time.now
          Timeout.timeout(10) do
            @logger.debug("Traceroute START : print route packets to host '#{@host}'")
            output = `traceroute #{@host} 2> /dev/null`
            @logger.debug("\n#{output}")
            @logger.info("Traceroute END - #{'%.5f' % (Time.now - time)} sec")
            output
          end
        rescue Timeout::Error => t
          @logger.warn("Skipped Traceroute for '#{@host}': #{t.message}  - #{'%.5f' % (Time.now - time)} sec")
        rescue
          @logger.warn("Skipped Traceroute for '#{@host}' - #{'%.5f' % (Time.now - time)} sec")
          nil
        end
      end      
    end

    class UrlChecker
      def initialize(url, logger = Logger.new($stdout))
        @url = url
        @logger = logger
      end

      def valid?
        begin
          time = Time.now
          if (`which curl > /dev/null; echo $?`).to_i.zero?
            output = `curl --silent --max-time 2 #{@url} > /dev/null; echo $?`
            result = output.chomp.to_i.zero?
            validation = result ? true : false
            @logger.info("Fetching #{@url} with curl => #{validation} - #{'%.5f' % (Time.now - time)} sec")
            result
          else
            output = `wget -q -O - #{@url} > /dev/null; echo $?`
            result = output.chomp.to_i.zero?
            @logger.info("Fetching #{@url} with wget => #{result} - #{'%.5f' % (Time.now - time)} sec")
            result
          end
        rescue
          @logger.warn("BLOCKER: Fetching #{@url} is nil - #{'%.5f' % (Time.now - time)} sec")
          nil
        end
      end
    end

    class LatencyChecker
      def initialize(url, logger = Logger.new($stdout))
        @url = url
        @logger = logger
      end

      def valid?
        begin
          time = Time.now
          output = if (`which curl > /dev/null; echo $?`).to_i.zero?
            `curl --connect-timeout 2 -w '#{Data::INPUT}' -o /dev/null -s #{@url}`
          else
            `wget -O - -q -t 1 --timeout=3 #{@url} > /dev/null; echo $?`  
          end
          total_latency = output.split("\n").last.split(' ').last.to_f
          valid = total_latency.to_f >= 0.0 && total_latency.to_f <= 0.5
          @logger.info("#{@url} latency check latency => #{total_latency}, latency check valid => #{valid} - #{'%.5f' % (Time.now - time)} sec")
          valid
        rescue
          @logger.warn("BLOCKER: latency for #{@url} out of range")
          false
        end
      end
    end
  end

  class Runner
    def self.run!(data = Data, io = $stdout)
      time = Time.now

      log_path = if File.directory?("#{ENV['HOME']}/Desktop/")
        "#{ENV['HOME']}/Desktop/"
      else
        ENV['HOME']
      end

      log_file = File.open("#{log_path}/SoundCloud_#{Time.now.strftime("%Y%m%d_%H:%M:%S")}.log", 'w')
      logger = Logger.new(log_file)
      logger.level = Logger::DEBUG
      logger.info("CONNECTIVITY SUITE - START #{Time.now}")

      logger.info(' ')
      logger.info('START HOST CHECKER')
      hash_dns_ip = {}

      data.webhosts.each do |line|
        single_dns_ip = {}
        io.print "checking '#{line}'  "
        checker = Features::HostChecker.new(line, logger)
        @result_ip = checker.valid_ip?
        io.puts "=>  IP connectivity #{@result_ip} "
        dns = checker.valid_dns? 
        @result_dns = dns ? true : false
        io.print " | DNS resolution #{@result_dns} "
        io.puts
        routes = checker.traceroute 
        single_dns_ip[line] = { 'ip_value'  =>  @result_ip, 'dns_value'  =>  @result_dns }
        logger.info(single_dns_ip.inspect)
        hash_dns_ip[line] = { 'ip_value'  =>  @result_ip, 'dns_value'  =>  @result_dns}
      end
      logger.info("RESULT HOST CHECKER: #{hash_dns_ip.inspect}")
      logger.info('END HOST CHECKER')
      logger.info(' ')

      hash_url = {}
      logger.info('START URL CHECKER')
      %w(http https).each do |protocol_name|
        data.domain_path.each do |host|
          io.print "checking protocol #{protocol_name} '#{host}'  "
          url = "#{protocol_name}://#{host}"
          checker = Features::UrlChecker.new(url, logger)
          output = checker.valid? 
          @protocol_result = output ? true : false
          io.print "=> #{@protocol_result} "
          io.puts
          logger.info("Checking protocol #{protocol_name} '#{host}' => #{@protocol_result} ")
          hash_url[protocol_name] = { url => output }
        end
      end
      logger.info("RESULT URL CHECKER: #{hash_url.inspect}")
      logger.info('END URL CHECKER')
      logger.info(' ')

      logger.info('START LATENCY CHECKER')
      hash_latency = {}
      %w(http https).each do |protocol_name|
        data.domain_path.each do |host|
          latency = Features::LatencyChecker.new(host, logger)
          single_latency = {}
          url = "#{protocol_name}://#{host}"
          io.print "checking latency for #{url} "
          @latency_result = latency.valid? 
          io.print " => #{@latency_result}"
          io.puts
          single_latency[protocol_name] = { url => @latency_result }
          hash_latency[protocol_name] = { url => @latency_result }
        end
      end
      logger.info("RESULT LATENCY CHECKER: #{hash_latency.inspect}")
      logger.info('END LATENCY CHECKER')
      logger.info(' ')

      duration = Time.now - time
      logger.info("CONNECTIVITY SUITE - END #{Time.now} Duartion: #{duration.inspect} sec")
    end
  end

  if __FILE__ == $PROGRAM_NAME
    if ARGV.empty?
      ConnectivitySuite::Runner.run!
    else ARGV == 'Happy'
         puts 'Hakkunamattata'
    end
  end
end
