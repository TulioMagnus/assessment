class ForecastsController < ApplicationController
  def new
  end

  def show
    @address = params[:address].to_s.strip
    return if @address.present?

    @error_message = "Please enter an address."
    render :new, status: :unprocessable_entity
  end
end
