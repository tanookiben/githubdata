class ApplicationController < ActionController::Base
  protect_from_forgery
  
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
  
end
