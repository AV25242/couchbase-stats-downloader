# couchbase-sdk-stats-downloader
Written using Couchbase Ruby SDK, this tool downloads Couchbase stats from npm, maven, nuget, rubygems etc into Couchbase datastore

For Maven download stats you will need sonatype account. The downloader will prompt you to enter the credentials when downloading Maven stats.

Download the sourcecode and execute the following line of code from Command line.

bundle install

ruby downloader.rb

Downloading stats for Python requires some steps to be followed. All of which can be found here

https://github.com/ofek/pypinfo/blob/master/README.rst

Once done, copy the JSON key file in the main directory alongside downloader.rb
