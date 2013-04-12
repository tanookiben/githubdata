class Parser < ActiveRecord::Base
  attr_accessible :parser_type, :event_type,
  								:date, :base_uri

  def self.date_to_string(date)
  	if date[:hour]
  		return "#{date[:year]}-#{date[:month]}-#{date[:day]}-#{date[:hour]}"
  	else
  		return "#{date[:year]}-#{date[:month]}-#{date[:day]}"
  	end
  end
end
