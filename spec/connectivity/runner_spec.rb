# require 'rspec'
# require File.join(File.dirname(__FILE__), '../..', 'connectivity')

# module ConnectivitySuite
#   module Input
#     def self.webhosts
#       HOSTS.keys
#     end

#     def self.domain_path
#       HOSTS.map { |k, v| k + v }
#     end

#     HOSTS = {
#       "soundcloud.com" => "/robots.txt"
#     }
#   end

#   describe Runner do
#     it 'should check run method for hostname "soundcloud"' do
#       output = StringIO.new
#       Runner.run!(Input, output)
#       str = output.string
#       output = File.read('spec/resources/latency-https-soundcl.com.log')
#       allow(subject).to receive(:`).and_return(output)
#       expect(str).to include("checking latency for http://soundcloud.com/robots.txt")
#       expect(str).to include("Resolved DNS")
#       expect(str).to include("checking protocol https 'soundcloud.com/robots.txt'")
#     end
#   end
# end
