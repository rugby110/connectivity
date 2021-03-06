require 'rspec'
require File.join(File.dirname(__FILE__), '../..', 'connectivity')

module ConnectivitySuite
  include Features
  describe LatencyChecker do
    let(:null_logger) { Logger.new(File.open('/dev/null', 'a')) }

    it "checks latency for secure requests against an valid host over port 80" do
      subject = LatencyChecker.new('http://soundcloud.com', null_logger)
      output = File.read('spec/resources/latency-http-soundcloud.com.log')
      allow(subject).to receive(:`).and_return(output)
      expect(subject).to_not be_valid
    end

    it "checks latency for secure requests against an valid host over port 443" do
      subject = LatencyChecker.new('https://soundcloud.com', null_logger)
      output = File.read('spec/resources/latency-https-soundcloud.com.log')
      allow(subject).to receive(:`).and_return(output)
      expect(subject).to be_valid
    end

    it "checks latency for secure requests against an invalid host over port 443" do
      subject = LatencyChecker.new('https://soundcl.com/', null_logger)
      output = File.read('spec/resources/latency-https-soundcl.com.log')
      allow(subject).to receive(:`).and_return(output)
      expect(subject).not_to be_valid
    end
  end
end
