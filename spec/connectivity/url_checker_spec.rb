require 'rspec'
require File.join(File.dirname(__FILE__), '../..', 'connectivity')

module ConnectivitySuite
  include Features
  describe UrlChecker do
    let(:null_logger) { Logger.new(File.open('/dev/null', 'a')) }
    describe 'Fetching data over port 443 ' do
      it 'checks if connection for port 443 is valid for google.com' do
        subject = UrlChecker.new('https://google.com', null_logger)
        allow(subject).to receive(:`).and_return("0\n")
        expect(subject).to be_valid
      end
    end

    describe 'Fetching data over port 80' do
      it 'checks if connection for port 80 is valid for host soundcloud.com' do
        subject = UrlChecker.new('http://soundcloud.com', null_logger)
        allow(subject).to receive(:`).and_return("6\n")
        expect(subject).not_to be_valid
      end
    end
  end
end
