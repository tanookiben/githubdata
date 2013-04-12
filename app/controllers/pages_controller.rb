class PagesController < ApplicationController
  def david_home
    @cities, @cityCoords, @cityMappings = convert_coordinates()
    gon.cities = @cities
    gon.cityCoords = @cityCoords
    gon.cityMappings = @cityMappings
  end

  def home
  end

  def demo
    @data = {}
  end

  def parse
  	@parser = Parser.find_by_date_and_parser_type_and_event_type(
  		params[:date],
  		params[:parser],
  		params[:event])
  	if @parser.nil?
  		@parser = Parser.create(
  			:date => params[:date],
  			:parser_type => params[:parser],
  			:event_type => params[:event])
  	end

    @query = "#{@date}|||||#{@parser.parser_type}|||||#{@parser.event_type}"

    Results.all.each do |result|
      if result.query == @query
        @lang_hours = process_results(@query)
        return
      end
    end


  	@dataset = []

  	@date = params[:date].split('-')
  	if @date.count == 4
  		@date = {
  			:year => @date[0],
  			:month => @date[1],
  			:day => @date[2],
  			:hour => @date[3]}
  	else
  		@date = {
  			:year => @date[0],
  			:month => @date[1],
  			:day => @date[2]}
  	end

    if @date[:hour]
      @dataset << "#{@parser.base_uri}#{@date[:year]}-#{@date[:month]}-#{@date[:day]}-#{@date[:hour]}.json.gz"
    elsif @date[:day]
      (0..23).each do |hour|
        @dataset << "#{@parser.base_uri}#{@date[:year]}-#{@date[:month]}-#{@date[:day]}-#{hour}.json.gz"
      end
    end

  	@push_event_count = 0
  	@lang_hours = {}

  	start = Time.now

  	require 'open-uri'
  	require 'zlib'
  	require 'yajl'

  	@dataset.each do |datafile|
  		puts "Checking #{datafile}."

  		gz = open(datafile)
  		js = Zlib::GzipReader.new(gz).read

  		Yajl::Parser.parse(js) do |event|
  			if event["type"] != @parser.event_type
  				next
  			else
  				@push_event_count += 1
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

  	if @date[:hour]
  		@date = "#{@date[:year]}-#{@date[:month]}-#{@date[:day]}-#{@date[:hour]}"
  	else
  		@date = "#{@date[:year]}-#{@date[:month]}-#{@date[:day]}"
  	end

  	@lang_hours.each do |hour, lang_hash|
  		lang_hash.each do |lang, cnt|
  			Results.create(:date => @date, :language => lang, :count => cnt, :hour => hour, :query => @query)
  		end
  	end

  	finish = Time.now
  	puts "Languages by hour took #{finish-start} seconds for #{@push_event_count} events."
  end

  private
    def process_results(query)
      @return = {}

      Results.all.each do |result|
        if @return[result.hour].nil?
          @return[result.hour] = {}
          @return[result.hour][result.language] = result.count
        else
          @return[result.hour][result.language] = result.count
        end
      end
      @return
    end
>>>>>>> added parsing of data with form from homepage; added bootstrap, skrollr, d3; working on a demo stacked bar chart for proof of concept
end
