class Results < ActiveRecord::Base
  attr_accessible :count, :date, :hour, :language, :query

  def self.update_results
    now = DateTime.now
    ago = DateTime.now - 10.days
    today = "#{now.month < 10 ? 0.to_s+now.month.to_s : now.month.to_s}-#{now.day < 10 ? 0.to_s+now.day.to_s : now.day.to_s}-#{now.year.to_s}"
    past = "#{ago.month < 10 ? 0.to_s+ago.month.to_s : ago.month.to_s}-#{ago.day < 10 ? 0.to_s+ago.day.to_s : ago.day.to_s}-#{ago.year.to_s}"

    Results.find_by_query(past).each do |old_query|
    	old_query.destroy
    end

    require 'open-uri'
    require 'zlib'
    require 'yajl'

    @query = today

    @dataset.each do |datafile|
    	gz = open(datafile)
    	js = Zlib::GzipReader.new(gz).read

    	Yajl::Parser.parse(js) do |event|
    		if event["type"] != "PushEvent"
    			next
    		end

    		hour = DateTime.striptime(event["created_at"]).hour

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
  end

  def self.generate_date(date_hash)
    if date_hash[:hour]
      @gen_date = "#{date_hash[:year]}-#{date_hash[:month]}-#{date_hash[:day]}-#{date_hash[:hour]}"
    else
      @gen_date = "#{date_hash[:year]}-#{date_hash[:month]}-#{date_hash[:day]}"
    end
    @gen_date
  end
end
