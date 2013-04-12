class PagesController < ApplicationController
  def home
    @cities, @cityCoords, @cityMappings = convert_coordinates()
    gon.cities = @cities
    gon.cityCoords = @cityCoords
    gon.cityMappings = @cityMappings
  end
end
