class PagesController < ApplicationController
  def home
  end

  def visualization
    session[:date] = params[:date]
    if params[:visualization] == "times"
      redirect_to select_path(:date => params[:date])
    elsif params[:visualization] == "locations"
      redirect_to locations_path
    end
  end

  def demo
    # Skrollr demo - ignore
    # @data = {}
    Results.update_results
    redirect_to root_path
  end
end
