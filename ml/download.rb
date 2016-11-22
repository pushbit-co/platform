require 'open-uri'

def download(url, dest)
  unless File.exists?(dest)
    puts "downloading: #{url}"

    open(dest, 'wb') do |file|
      file << open(url).read
    end
  end
end

# training set
months = (1..1).to_a
days = (1..30).to_a
hours = (0..23).to_a

months.each do |month|
  month = sprintf '%02d', month

  days.each do |day|
    day = sprintf '%02d', day

    hours.each do |hour|
      file_name = "2016-#{month}-#{day}-#{hour}.json.gz"
      file_path = "ml/corpus/#{file_name}"
      url = "http://data.githubarchive.org/#{file_name}"
      download(url, file_path)
    end
  end
end

# testing set
months = (2..2).to_a
days = (1..2).to_a
hours = (0..23).to_a

months.each do |month|
  month = sprintf '%02d', month

  days.each do |day|
    day = sprintf '%02d', day

    hours.each do |hour|
      file_name = "2016-#{month}-#{day}-#{hour}.json.gz"
      file_path = "ml/testing/#{file_name}"
      url = "http://data.githubarchive.org/#{file_name}"
      download(url, file_path)
    end
  end
end
