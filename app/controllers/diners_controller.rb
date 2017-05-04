class DinersController < ApplicationController
  before_action :set_restaurant, only: %i[index show edit update]
  before_action :set_diner, only: %i[show edit update]

  def index
    @diners = Reservation.where(restaurant_id: params[:restaurant_id], status: 'dining')
  end

  def edit; end

  def show; end

  def update
    if @diner.update(diner_params)
      redirect_to restaurant_diners_path(@restaurant)
    else
      render :edit
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_diner
    @diner = Reservation.find(params[:id])
  end

  def diner_params
    params.require(:reservation).permit(:name, :phone, :email, :party_size, :special_requests, :status)
  end
end
