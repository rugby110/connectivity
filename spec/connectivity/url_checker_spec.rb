require 'rspec'
require File.join(File.dirname(__FILE__), '../..', 'connectivity')

module ConnectivitySuite
  include Features
  describe UrlChecker do
    let(:null_logger) { Logger.new(File.open('/dev/null', 'a')) }
    describe 'checking 443 connectivity' do
      it 'checks if port 443 is open for google.com' do
        subject = UrlChecker.new('https://google.com', null_logger)
        allow(subject).to receive(:`).and_return("0\n")
        expect(subject).to be_valid
      end
    end

    describe 'checking port 80 connectivity' do
      it 'checks if port 80 is open for the host soundcloud.com' do
        subject = UrlChecker.new('http://soundcloud.com', null_logger)
        allow(subject).to receive(:`).and_return("6\n")
        expect(subject).not_to be_valid
      end
    end
  end
end
