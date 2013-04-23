class PagesController < ApplicationController
  def home
  end

  def visualization
    session[:date] = params[:date]
    if params[:visualization] == "times"
      redirect_to times_path
    elsif params[:visualization] == "locations"
      redirect_to locations_path
    end
  end

  def demo
    # Skrollr demo - ignore
    @data = {}
  end
end
