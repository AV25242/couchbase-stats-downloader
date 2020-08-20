require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'io/console'
require 'active_support/core_ext'
require 'date'

require_relative 'storage'


#ruby download is agnostic of month or year
def download_and_save_rubygems_stats()
  begin
    input  = Date.today.strftime("%Y%m")
    repo = "rubygems"
    url = "https://rubygems.org/api/v1/versions/couchbase.json"

    year = input.to_s[0,4]
    month  = input.to_s[4,2]

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
          stats["client"] = []

          items.each do |item|
            client = { item["name"] => item["count"] }
            stats["client"] << client
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

def download_and_save_npm_stats(input, component = "couchbase")
begin
    repo ="npm"
    year  = input.to_s[0,4]
    month = input.to_s[4,2]
    startdate  = Date.new(year.to_i,month.to_i,1)
    enddate = startdate.end_of_month.strftime("%Y-%m-%d")
    startdate = startdate.strftime("%Y-%m-%d")

    url = "https://api.npmjs.org/downloads/range/#{startdate}:#{enddate}/#{component}"

    component = (component == "couchbase") ? "node-sdk" : "ottoman"

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

          count  = 0
          source["downloads"].each do |item|
              count += item["downloads"]
          end

          stats["client"] << {component => count}
          stats["total"] = count
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

def download_and_save_nuget_stats(component = "CouchbaseNetClient")
begin
    input  = Date.today.strftime("%Y%m")

    year  = input.to_s[0,4]
    month = input.to_s[4,2]
    repo = "nuget"

    url = "https://api-v2v3search-0.nuget.org/query?q=packageid:#{component}"

    component = (component == "CouchbaseNetClient") ? "dotnet-sdk" : "Linq"

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

          version2count  = 0
          version3count = 0
          others = 0

          source["data"][0]["versions"].each do |item|
            version  = item["version"].to_s[0,1]

            if version == "2"
               version2count += item["downloads"]
            elsif version == "3"
               version3count += item["downloads"]
            else
               others += item["downloads"]
            end
          end

          stats["client"] << { "#{component}3.x"  => version3count}
          stats["client"] << { "#{component}2.x"  => version2count}
          stats["client"] << { "#{component}"  => others}
          stats["total"] = source["data"][0]["totalDownloads"]

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

def save(key,stats)
  res = Storage.instance.collection.upsert(key,stats)
  #stats = Storage.instance.collection.get(stats)
end

def download()

    puts "Which Statistics would you like to download ? "
    puts "Enter 1 for Rubygem. "
    puts "Enter 2 for Nuget. "
    puts "Enter 3 for Npm. "
    puts "Enter 4 for Maven. "
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
      when "10"
        puts "Enter the year and month for download format : yyyymm"
        downloadMonth = gets.strip
        download_and_save_rubygems_stats()
        download_and_save_nuget_stats()
        download_and_save_npm_stats(downloadMonth)
        download_and_save_maven_stats(downloadMonth)
      else
          puts "Good Bye.."
    end
end

download()