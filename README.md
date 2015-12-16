#ConnectivitySuite#

[![Build Status]()][jenkins]

## Introduction
With the Connectivity Suite we provide a script that can be executed on the users machine which tests if everything is working properly to load the soundcloud.com website and play tracks.
Use-Case
When the Community Operations Team receives a report that a user has issues loading soundcloud.com on a desktop computer, they will send an command line to the user that can be copy/pasted to the users shell. During the execution of the Connectivity Suite, technical but understandable output will be printed to the console. Additionally, a log file will be written to the users desktop directory. After the Connectivity Suite has finished, the user will be asked to send the log file back to the community person who will forward it to the Systems and Traffic Engineering Team that will debug the problem further.

### Execution
Three steps to run the script:

    1. open terminal
     2. type 
        OSX
            `curl https://raw.githubusercontent.com/soundcloud/connectivity/master/connectivity.rb | ruby `
        Linux
            `ruby <(wget -qO- https://raw.githubusercontent.com/soundcloud/connectivity/master/connectivity.rb)`
    
    --> "run, connectivity suite, run"

### Download the code
Get the code and run the full test suite as follows:

    git clone git@github.com:soundcloud/connectivity.git

    $ bundle install
    $ bundle exec rspec
    $ ruby connectivity.rb

It is built for Ruby >= 1.8.7. for Mac OS X and Linux.

## Testing
Run the Rspec Tests:

    1. open terminal, make sure rspec is installed
    2. redirect to connectivity suite directory
    3. type `$ rspec`


## Planned functionality
* Tests if all Soundcloud Domains resolve correctly to Edgecast & Cloudfront
* Checks IP Connectivity and verfifies http & htpps connection to all SoundCloud IPs
* Measures http & https latencies
* Continuous integration

Following OSI-Modell Layers:
    Hostname/IP translation
    DNS
    Layer 3 connection
    ICMP
    Layer 4 connection
    TCP
    Layer 7 connection
    HTTP
    HTTPS


## Versioning
Connectivity Suite adheres to Semantic Versioning 2.0.0. If there is a violation of this scheme, report it as a bug. Specifically, if a patch or minor version is
released and breaks backward compatibility, that version should be immediately yanked and/or a new version should be immediately released that restores
compatibility. Any change that breaks the public API will only be introduced at a major-version release. As a result of this policy, you can (and should)
specify any dependency on Connectivity Suite by using the Pessimistic Version Constraint with two digits of precision.

## Licensing
See the [LICENSE](https://github.com/soundcloud/connectivity/blob/master/%20LICENSE.md) file for details.
