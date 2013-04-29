class Results < ActiveRecord::Base
  attr_accessible :count, :date, :hour, :language, :query

  def self.update_results
    puts "starting update_results"
    start = Time.now

    now = DateTime.now - 1.day
    ago = DateTime.now - 10.days
    today = "#{now.year.to_s}-#{now.month < 10 ? 0.to_s+now.month.to_s : now.month.to_s}-#{now.day < 10 ? 0.to_s+now.day.to_s : now.day.to_s}"
    past = "#{ago.year.to_s}-#{ago.month < 10 ? 0.to_s+ago.month.to_s : ago.month.to_s}-#{ago.day < 10 ? 0.to_s+ago.day.to_s : ago.day.to_s}"

    Results.find_all_by_query(past).each do |old_query|
    	old_query.destroy
    end

    require 'open-uri'
    require 'zlib'
    require 'yajl'

    @query = today
    @date = Results.parse_date(today)
    @dataset = create_dataset(@date)

    @lang_hours = {}

    @dataset.each do |datafile|
        puts "checking #{datafile}"
    	gz = open(datafile)
    	js = Zlib::GzipReader.new(gz).read

    	Yajl::Parser.parse(js) do |event|
    		if event["type"] != "PushEvent"
    			next
    		end

    		hour = DateTime.strptime(event["created_at"]).hour

    		if event["repository"].nil? || event["repository"].empty?
    			next
    		end

    		lang = event["repository"]["language"]

    		if lang.nil? || lang == ""
    			next
    		end

    		if @lang_hours[hour].nil?
    			@lang_hours[hour] = {lang => 1}
    		else
    			if @lang_hours[hour][lang].nil?
    				@lang_hours[hour][lang] = 0
    			end
    			@lang_hours[hour][lang] += 1
    		end
    	end
    end

    @date = Results.generate_date(@date)

    @lang_hours.each do |hour, lang_hash|
    	lang_hash.each do |lang, cnt|
    		Results.create(:date => @date, :language => lang, :count => cnt, :hour => hour, :query => @query)
    	end
    end

    Query.create(:query => @query, :vis => "times")

    finish = Time.now
    puts "finishing update_results"
    puts "update_results took #{finish - start} seconds"
  end

  def self.generate_date(date_hash)
    if date_hash[:hour]
      @gen_date = "#{date_hash[:year]}-#{date_hash[:month]}-#{date_hash[:day]}-#{date_hash[:hour]}"
    else
      @gen_date = "#{date_hash[:year]}-#{date_hash[:month]}-#{date_hash[:day]}"
    end
    @gen_date
  end

  def self.create_dataset(date)
    @new_dataset = []
    if date[:hour]
      @new_dataset << "http://data.githubarchive.org/#{date[:year]}-#{date[:month]}-#{date[:day]}-#{date[:hour]}.json.gz"
    elsif date[:day]
      (0..23).each do |hour|
        @new_dataset << "http://data.githubarchive.org/#{date[:year]}-#{date[:month]}-#{date[:day]}-#{hour}.json.gz"
      end
    end
    @new_dataset
  end

  def self.parse_date(date_field)
    @split_date = date_field.split('-')
    if @split_date.length == 4
      @split_date = {
        :year => @split_date[0],
        :month => @split_date[1],
        :day => @split_date[2],
        :hour => @split_date[3]}
    else
      @split_date = {
        :year => @split_date[0],
        :month => @split_date[1],
        :day => @split_date[2]}
    end
    @split_date
  end
end
