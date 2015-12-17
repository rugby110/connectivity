require 'rspec'
require File.join(File.dirname(__FILE__), '../..', 'connectivity')

module ConnectivitySuite
  include Features
  describe HostChecker do
    let(:null_logger) { Logger.new(File.open('/dev/null', 'a')) }
    describe '#ip method' do
      subject do
        HostChecker.new('soundcloud.com', null_logger)
      end
      it 'checks if dig method uses expected input and returns valid IP' do
        expect(subject).to receive(:`).with('dig +short soundcloud.com').and_return('93.184.220.127')
        subject.ip
      end
      it 'checks if dig method returns valid IP for valid host' do
        allow(subject).to receive(:`).and_return("93.184.220.127\n")
        result = subject.ip
        expect(result).to eq('93.184.220.127')
      end
    end

    describe '#edgecast?' do
      it 'checks if valid Soundcloud domain resolve correctly to Edgecast' do
        output = File.read('spec/resources/curl-soundcloud.com.log')
        subject = HostChecker.new('soundcloud.com', null_logger)
        allow(subject).to receive(:get).and_return(output)
        expect(subject).to be_edgecast
      end
      it 'checks if invalid domain fails to resolve to Edgecast' do
        output = File.read('spec/resources/curl-wis.sndcdn.com.log')
        subject = HostChecker.new('wis.sndcdn.com', null_logger)
        allow(subject).to receive(:get).and_return(output)
        expect(subject).not_to be_edgecast
      end
      it 'checks if valid Soundcloud domain resolve correctly to Edgecast' do
        output = File.read('spec/resources/curl-i2.sndcdn.com.log')
        subject = HostChecker.new('i2.sndcdn.com', null_logger)
        allow(subject).to receive(:get).and_return(output)
        expect(subject).to be_edgecast
      end
      it 'checks if valid Soundcloud domain resolve correctly to Edgecast, test contains unicode' do
        output = File.read('spec/resources/curl-fake.com.log')
        subject = HostChecker.new('soundcloud.com', null_logger)
        allow(subject).to receive(:get).and_return(output)
        expect(subject).to be_edgecast
      end
    end

    describe '#cloudfront?' do
      it 'checks if valid Soundcloud domain resolve correctly to Cloudfront' do
        output = File.read('spec/resources/curl-cf-media.sndcdn.com.log')
        subject = HostChecker.new('cf-media.sndcdn.com', null_logger)
        allow(subject).to receive(:get).and_return(output)
        expect(subject).to be_cloudfront
      end
      it 'checks if invalid domain fails to resolve to Cloudfront' do
        output = File.read('spec/resources/whois-soundcloud.com.log')
        subject = HostChecker.new('soundcloud.com', null_logger)
        allow(subject).to receive(:get).and_return(output)
        expect(subject).not_to be_cloudfront
      end
    end

    describe 'checks if hostnames file processes DNS' do
      Data.webhosts.each do |host|
        it "checks if valid SoundCloud #{host} has valid DNS" do
          subject = HostChecker.new(host, null_logger)
          allow(subject).to receive(:get).and_return('EDGECAST')
          expect(subject).to be_valid_dns
        end
      end
      Data.webhosts.each do |host|
        it "checks if valid SoundCloud #{host} returns back tracerout" do
          subject = HostChecker.new(host, null_logger)
          traceroute = File.read('spec/resources/traceroute_cf-media.sndcdn.com.log')
          allow(subject).to receive(:`).and_return(traceroute)
          expect(subject.traceroute).to include('hbg-bb1-link.telia.net')
        end
      end
    end
        
    describe 'ping count method' do
      it 'should return true for 0,0% package loss when soundcloud.com is pinged' do
        subject = HostChecker.new('soundcloud.com', null_logger)
        output = File.read('spec/resources/ping-soundcloud.com.log')
        expect(subject).to be_zero_packets_lost(output)
      end
      it 'should return true for 0,0% package loss when ec-media.sndcdn.com is pinged' do
        subject = HostChecker.new('ec-media.sndcdn.com', null_logger)
        output = File.read('spec/resources/ping-ec-media.sndcdn.com.log')
        expect(subject).to be_zero_packets_lost(output)
      end
      it 'should return true for 0,0% package loss when eventgateway.soundcloud.com is pinged' do
        subject = HostChecker.new('api.soundcloud.com', null_logger)
        output = File.read('spec/resources/ping-api.soundcloud.com.log')
        expect(subject).to be_zero_packets_lost(output)
      end
    end

    describe 'timeout method' do
      it 'checks if ping for soundcloud.log is within timeout < 300ms' do
        subject = HostChecker.new('soundcloud.com', null_logger)
        output = File.read('spec/resources/ping-soundcloud.com.log')
        expect(subject).to be_within_timeout(output)
      end
      it 'checks if ping for ec-media.sndcdn.log is within timeout < 300ms' do
        subject = HostChecker.new('ec-media.sndcdn.com', null_logger)
        output = File.read('spec/resources/ping-ec-media.sndcdn.com.log')
        expect(subject).to be_within_timeout(output)
      end
      it 'checks if ping for ping_i4.sndcdn.log is within timeout < 300ms' do
        subject = HostChecker.new('i4.sndcdn.com', null_logger)
        output = File.read('spec/resources/ping-i4.sndcdn.com.log')
        expect(subject).to be_within_timeout(output)
      end
    end

    describe 'processing hostnames file for IP connectivity' do
      Data.webhosts.each do |host|
        it "checks if ip connectivity is valid for #{host} " do
          subject = HostChecker.new(host, null_logger)
          output = File.read("spec/resources/ping-#{host}.log")
          allow(subject).to receive(:ping).and_return(output)
          expect(subject).to be_valid_ip
        end
      end
    end

    describe 'checking 443 connectivity' do
      it 'checks if port 443 is open for google.com' do
        output = File.read("spec/resources/curl-google.com.log")
        subject = UrlChecker.new('https://google.de', null_logger)
        allow(subject).to receive(:`).and_return(output)
        expect(subject).to be_valid
      end
    end

    describe 'checking port 80 connectivity' do
      it 'checks if port 80 is open for the host soundcloud.com' do
        output = File.read("spec/resources/curl-http-soundcloud.com.log")
        subject = UrlChecker.new('http://soundcloud.com', null_logger)
        allow(subject).to receive(:`).and_return(output)
        expect(subject).to be_valid
      end
    end

    describe Data do
      describe '.webhosts' do
        it 'checks if webhost method returns an array of hosts including "soundcloud.com"' do
          expect(subject.webhosts).to include('soundcloud.com')
          expect(subject.webhosts).to include('ec-media.sndcdn.com')
        end
      end

      describe '.domain_path' do
        it 'checks if webhost method returns an array of urls including "soundcloud.com/robots.txt"' do
          expect(subject.domain_path).to include('soundcloud.com/robots.txt')
          expect(subject.domain_path).to include('ec-media.sndcdn.com/crossdomain.xml')
        end
      end
    end
  end
end
