class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def create_dataset(date_field)
    puts "date_field #{date_field}"
    @new_dataset = []
    if date_field[:hour]
      @new_dataset << "http://data.githubarchive.org/#{date_field[:year]}-#{date_field[:month]}-#{date_field[:day]}-#{date_field[:hour]}.json.gz"
    elsif date_field[:day]
      (0..23).each do |hour|
        @new_dataset << "http://data.githubarchive.org/#{date_field[:year]}-#{date_field[:month]}-#{date_field[:day]}-#{hour}.json.gz"
      end
    end
    puts "dataset #{@new_dataset}"
    @new_dataset
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
  
end
