class TimesController < ApplicationController

  def show
    start_method = Time.now

  	@date = parse_date(session[:date])

    @query = "#{session[:date]}"

    skip_parse = false
    if !Query.find_by_query_and_vis(@query,"times").nil?
      @lang_hours = retrieve_results(@query)
      skip_parse = true
    else
      Query.create(:query => @query, :vis => "times")
    end

    if !skip_parse
      @dataset = create_dataset(@date)

    	@push_event_count = 0
    	@lang_hours = {}

    	start_query = Time.now

    	require 'open-uri'
    	require 'zlib'
    	require 'yajl'

    	@dataset.each do |datafile|
    		puts "Checking #{datafile}."

    		gz = open(datafile)
    		js = Zlib::GzipReader.new(gz).read

    		Yajl::Parser.parse(js) do |event|
    			if event["type"] != "PushEvent"
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

      finish_query = Time.now
      puts "Languages by hour took #{finish_query-start_query} seconds for #{@push_event_count} events."
    end

    # @lang_hours = filter_count(@lang_hours, 100)
    @languages = ["Ruby"] #, "Java", "C", "PHP", "Python"]
    @lang_hours = filter_languages(@lang_hours, @languages)

    @lang_hours = normalize_values(@lang_hours)
    # @unique_languages = count_languages(@lang_hours)

    finish_method = Time.now
    puts "Parsing took #{finish_method-start_method} seconds to parse events."
  end

  private
    def filter_values(results, bound) # Keep languages with number of events greater than input bound
      results.each do |hour, lang_hash|
        lang_hash.keep_if { |lang, cnt| cnt > bound }
      end
      results
    end

    def filter_languages(results, languages) # Keep languages specified by an array of allowed languages
      results.each do |hour, lang_hash|
        lang_hash.keep_if { |lang, cnt| languages.include?(lang) }
      end
      results
    end

    def normalize_values(results) # Normalize results of language events per hour
      @languages.each do |sel_lang|
        lang_max = 0
        results.each do |hour, lang_hash|
          lang_hash.each do |lang, cnt|
            if lang == sel_lang && cnt > lang_max
              lang_max = cnt
            end
          end
        end
        puts "Lang #{sel_lang} max is #{lang_max}."
        results.each do |hour, lang_hash|
          lang_hash.each do |lang, cnt|
            if lang == sel_lang
              lang_hash[lang] = cnt.to_f / lang_max.to_f
            end
          end
        end
      end
      results
    end

    def count_languages(values) # Count the number of unique languages
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

    def retrieve_results(query) 
      @return = {}

      results = Results.find_all_by_query(@query)
      results.each do |result|
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

end