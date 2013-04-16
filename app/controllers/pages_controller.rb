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
    @parser = create_parser(params[:date], params[:parser], params[:event])

  	@date = parse_date(params[:date])

    @query = "#{params[:date]}|||||#{@parser.parser_type}|||||#{@parser.event_type}"

    skip_parse = false
    Results.all.each do |result|
      if result.query == @query
        @lang_hours = process_results(@query)
        skip_parse = true
      end
    end

    if !skip_parse
      @dataset = create_dataset(@date)

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

      @date = generate_date(@date)

    	@lang_hours.each do |hour, lang_hash|
    		lang_hash.each do |lang, cnt|
    			Results.create(:date => @date, :language => lang, :count => cnt, :hour => hour, :query => @query)
    		end
    	end

      finish = Time.now
      puts "Languages by hour took #{finish-start} seconds for #{@push_event_count} events."
    end

    # @lang_hours = filter_count(@lang_hours, 100)
    @languages = ["Ruby", "Java", "C", "PHP", "Python"]
    @lang_hours = filter_languages(@lang_hours, @languages)

    @lang_hours = normalize_values(@lang_hours)
    @unique_languages = count_languages(@lang_hours)
  end

  private
    def filter_values(results, bound)
      results.each do |hour, lang_hash|
        lang_hash.keep_if { |lang, cnt| cnt > bound }
      end
      results
    end

    def filter_languages(results, languages)
      results.each do |hour, lang_hash|
        lang_hash.keep_if { |lang, cnt| languages.include?(lang) }
      end
      results
    end

    def normalize_values(results)
      @languages.each do |sel_lang|
        lang_max = 0
        results.each do |hour, lang_hash|
          lang_hash.each do |lang, cnt|
            if lang == sel_lang && cnt > lang_max
              lang_max = cnt
            end
          end
          lang_hash.each do |lang, cnt|
            if lang == sel_lang
              lang_hash[lang] = cnt.to_f / lang_max.to_f
            end
          end
        end
      end
      results
    end

    def count_languages(values)
      uniques = []
      values.each do |hour, lang_hash|
        lang_hash.each do |lang, cnt|
          if !uniques.include?(lang)
            uniques << lang
          end
        end
      end
      uniques.count
    end

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

    def generate_date(date_hash)
      if date_hash[:hour]
        @gen_date = "#{date_hash[:year]}-#{date_hash[:month]}-#{date_hash[:day]}-#{date_hash[:hour]}"
      else
        @gen_date = "#{date_hash[:year]}-#{date_hash[:month]}-#{date_hash[:day]}"
      end
      @gen_date
    end

    def parse_date(date_field)
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

    def create_parser(date_field, parser_field, event_field)
      @new_parser = Parser.find_by_date_and_parser_type_and_event_type(
        date_field,
        parser_field,
        event_field)
      if @new_parser.nil?
        @new_parser = Parser.create(
          :date => date_field,
          :parser_type => parser_field,
          :event_type => event_field)
      end
      @new_parser
    end

    def create_dataset(date_field)
      @new_dataset = []
      if date_field[:hour]
        @new_dataset << "#{@parser.base_uri}#{date_field[:year]}-#{date_field[:month]}-#{date_field[:day]}-#{date_field[:hour]}.json.gz"
      elsif date_field[:day]
        (0..23).each do |hour|
          @new_dataset << "#{@parser.base_uri}#{date_field[:year]}-#{date_field[:month]}-#{date_field[:day]}-#{hour}.json.gz"
        end
      end
      @new_dataset
    end
>>>>>>> proof of concept for css based graphs
end
