require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'io/console'
require 'active_support/core_ext'
require 'date'
require 'open3'

require_relative 'storage'


#ruby download is agnostic of month or year
def download_and_save_rubygems_stats()
  begin
    input  = Date.today.strftime("%Y%m")
    repo = "rubygems"
    url = "https://rubygems.org/api/v1/versions/couchbase.json"

    year = input.to_s[0,4]
    month  = input.to_s[4,2]
    lastupdate = DateTime.now.strftime("%Y-%m-%d %H:%M")
    uri = URI(url)

    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https',
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

      request = Net::HTTP::Get.new uri.request_uri


      request["Accept"] =  'application/json'

      puts " Begin downloading #{repo} data from #{url} "
      response = http.request request # Net::HTTPResponse object


      if response.code == "200"
          puts " Downloading #{repo} data completed. "
          source = JSON.parse(response.body)

          stats = Hash.new(0)

          stats["type"] = repo
          stats["year"] = year
          stats["month"] = month
          stats["lastupdate"] = lastupdate
          stats["client"] = []

          count  = 0

          source.each do |item|
              if item["number"].to_s[0,1].to_i >= 3 then
                count += item["downloads_count"]
              end
          end

          stats["client"] << {"ruby" => count}
          stats["total"] = count

          output  = {
              stats: stats,
              source:source
           }
           save("#{input}::#{repo}", output)
          return output,true
      else
          puts response

          return nil,false
      end

     end
   rescue => ex
      puts ex
      return nil,false
   end

end

def download_and_save_maven_stats(input)
begin
    url = "https://oss.sonatype.org/service/local/stats/slices?p=141f284649826b&g=com.couchbase.client&t=raw&from=#{input}&nom=1"
    repo = "maven"
    uri = URI(url)
    year  = input.to_s[0,4]
    month  = input.to_s[4,2]
    lastupdate = DateTime.now.strftime("%Y-%m-%d %H:%M")

    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https',
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

      request = Net::HTTP::Get.new uri.request_uri

      puts "Enter oss.sonatype.org Username:"
      username = gets.strip
      password = IO::console.getpass "Enter oss.sonatype.org Password:"

      request.basic_auth username, password
      request["Accept"] =  'application/json'

      puts " Begin downloading #{repo} data from #{url} "
      response = http.request request # Net::HTTPResponse object

      if response.code == "200"
          puts " Downloading #{repo} data completed. "
          source = JSON.parse(response.body)

          items  = source["data"]["slices"]


          stats = Hash.new(0)
          stats["total"] = source["data"]["total"]
          stats["type"] = repo
          stats["year"] = year
          stats["month"] = month
          stats["lastupdate"] = lastupdate
          stats["client"] = []

          kafkacount = 0
          scalacount = 0
          sparkcount = 0
          items.each do |item|
            name  = item["name"].split('-')
            if name[0] == "kafka"
                kafkacount +=item["count"]
            elsif name[0] == "spark"
                sparkcount +=item["count"]
            elsif name[0] == "scala"
                scalacount +=item["count"]
            else
                 client = { item["name"] => item["count"] }
                 stats["client"] << client
            end

          end
          client = { "kafka-connector" => kafkacount }
          stats["client"] << client

          client = { "scala" => scalacount }
          stats["client"] << client

          client = { "spark-connector" => sparkcount }
          stats["client"] << client



          output  = {
              stats: stats,
              source:source
           }
           puts " Save #{repo} data begin. "
            save("#{input}::#{repo}", output)
           puts " Save #{repo} data completed . "

          return output,true
      else
         puts response
          return nil,false
      end
   end
rescue => ex
  puts ex
  return nil,false
end

end

def download_and_save_npm_stats(input)
begin
    repo ="npm"
    year  = input.to_s[0,4]
    month = input.to_s[4,2]
    startdate  = Date.new(year.to_i,month.to_i,1)
    enddate = startdate.end_of_month.strftime("%Y-%m-%d")
    startdate = startdate.strftime("%Y-%m-%d")
    lastupdate = DateTime.now.strftime("%Y-%m-%d %H:%M")

    url = "https://api.npmjs.org/downloads/range/#{startdate}:#{enddate}/couchbase,ottoman"

    uri = URI(url)

    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https',
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

      request = Net::HTTP::Get.new uri.request_uri


      request["Accept"] =  'application/json'

      puts " Begin downloading #{repo} data from :  #{url} "
      response = http.request request # Net::HTTPResponse object

      if response.code == "200"
          puts " Downloading #{repo} data completed. "
          source = JSON.parse(response.body)

          stats = Hash.new(0)

          stats["type"] = repo
          stats["year"] = year
          stats["month"] = month
          stats["client"] = []
          stats["lastupdate"] = lastupdate

          ottomancount  = 0
          nodecount  = 0
          source["ottoman"]["downloads"].each do |item|
              ottomancount += item["downloads"]
          end

          stats["client"] << {"ottoman" => ottomancount}

          source["couchbase"]["downloads"].each do |item|
              nodecount += item["downloads"]
          end

          stats["client"] << {"node-sdk" => nodecount}

          stats["total"] = nodecount + ottomancount

          output  = {
              stats: stats,
              source:source
           }

          puts " Save #{repo} data begin. "
          save("#{input}::#{repo}", output)
          puts " Save #{repo} data completed . "
          return output,true
      else
         puts response
          return nil,false
      end
     end
rescue => ex
   puts ex
   return nil,false
end
end

def download_and_save_nuget_stats()
begin
    input  = Date.today.strftime("%Y%m")
    lastupdate = DateTime.now.strftime("%Y-%m-%d %H:%M")
    client = ["CouchbaseNetClient","Linq2Couchbase","CouchbaseAspNet"]

    year  = input.to_s[0,4]
    month = input.to_s[4,2]
    repo = "nuget"

    url = "https://api-v2v3search-0.nuget.org/query?q=owner:couchbase"

    uri = URI(url)

    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https',
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

      request = Net::HTTP::Get.new uri.request_uri


      request["Accept"] =  'application/json'

      puts " Begin downloading #{repo} data from :  #{url} "
      response = http.request request # Net::HTTPResponse object

      if response.code == "200"
          puts " Downloading #{repo} data completed. "
          source = JSON.parse(response.body)

          stats = Hash.new(0)

          stats["type"] = repo
          stats["year"] = year
          stats["month"] = month
          stats["lastupdate"] = lastupdate
          stats["client"] = []

          source["data"].each do |ele|

            count = 0

             if client.any?(ele["id"])

                ele["versions"].each do |item|
                  version  = item["version"].to_s[0,3].to_f
                  if ele["id"] == "CouchbaseNetClient"
                    if version >= 2.7
                      count += item["downloads"]
                    end
                  else
                    count += item["downloads"]
                  end
                end
                stats["client"] << { "#{ele["id"]}"  => count}            
                stats["total-#{ele["id"]}"] = ele["totalDownloads"]
              end
           end

          output  = {
              stats: stats,
              source:source
           }
         puts " Save #{repo} data begin. "
         save("#{input}::#{repo}", output)
         puts " Save #{repo} data completed . "
          return output,true
      else
          puts response
          return nil,false
      end

     end
rescue => ex
  puts ex
  return nil,false
end
end

def download_and_save_python_stats()
begin
  input  = Date.today.strftime("%Y%m")

  year  = input.to_s[0,4]
  month = input.to_s[4,2]
  repo = "pypi"
  lastupdate = DateTime.now.strftime("%Y-%m-%d %H:%M")

  component = "python-sdk"
  cmd  = "pypinfo --json couchbase version"

  source = nil

  puts " Begin downloading #{repo} data  "
  Open3.pipeline_rw cmd do |stdin, stdout, _ts|
    out = stdout.read
    source = JSON.parse(out)
  end
  Process.waitall
  puts " Downloading #{repo} data completed. "
  stats = Hash.new(0)

  stats["type"] = repo
  stats["year"] = year
  stats["month"] = month
  stats["lastupdate"] = lastupdate
  stats["client"] = []

  version2count  = 0
  version3count = 0
  others = 0
  count  = 0

  source["rows"].each do |item|
  version  = item["version"].to_s[0,1]

    if version == "2"
       version2count += item["download_count"]
    elsif version == "3"
       version3count += item["download_count"]
    else
       others += item["download_count"]
    end
    count+=item["download_count"]
  end

  stats["client"] << { "#{component}3.x"  => version3count}
  stats["client"] << { "#{component}2.x"  => version2count}
  stats["client"] << { "#{component}"  => others}
  stats["total"] = count

  output  = {
      stats: stats,
      source:source
   }
 puts " Save #{repo} data begin. "
 save("#{input}::#{repo}", output)
 puts " Save #{repo} data completed . "

return output,true
  #puts "output is " + source
rescue => ex
  puts  ex
  return nil,false
end
end

def save(key,stats)
  res = Storage.instance.collection.upsert(key,stats)
end

def download()

    puts "Which Statistics would you like to download ? "
    puts "Enter 1 for Rubygem. "
    puts "Enter 2 for Nuget. "
    puts "Enter 3 for Npm. "
    puts "Enter 4 for Maven. "
    puts "Enter 5 for python. "
    puts "Enter 10 for All. "
    puts "Press any other key to exit."

    input = gets.strip

    case input
      when "1"
        download_and_save_rubygems_stats()
      when "2"
        download_and_save_nuget_stats()
      when "3"
        puts "Enter the year and month for download format : yyyymm"
        downloadMonth = gets.strip
        download_and_save_npm_stats(downloadMonth)
      when "4"
        puts "Enter the year and month for download format : yyyymm"
        downloadMonth = gets.strip
        download_and_save_maven_stats(downloadMonth)
      when "5"
        download_and_save_python_stats()
      when "10"
        puts "Enter the year and month for download format : yyyymm"
        downloadMonth = gets.strip
        download_and_save_rubygems_stats()
        download_and_save_nuget_stats()
        download_and_save_npm_stats(downloadMonth)
        download_and_save_maven_stats(downloadMonth)
        download_and_save_python_stats()
      else
          puts "Good Bye.."
    end
end

download()
