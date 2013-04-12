class PagesController < ApplicationController
  def home
    @cities, @city_coord, @coordinates = convert_coordinates()
    gon.cities = @cities
    gon.city_coord = @city_coord
    gon.coordinates = @coordinates
  end
end
