class WalkinsController < ApplicationController
  before_action :set_restaurant, only: %i[index new create public_new public_create public_show edit update destroy]
  before_action :set_walkin, only: %i[show edit update destroy]
  # before_action :find_queue_number, only: %i[create]
  helper WalkinHelper

  def index
    @walkins = Reservation.where(restaurant_id: params[:restaurant_id], status: 'queuing')
  end

  def create
    @walkin = Reservation.new(walkin_params)
    @walkin.restaurant_id = @restaurant.id
    @walkin.queue_number = find_queue_number
    set_restaurant_queue()
    if @walkin.save!
      redirect_to restaurant_walkins_path(@restaurant)
    else
      render :new
    end
  end

  def new
    @walkin = Reservation.new
  end

  def public_create
    @walkin = Reservation.new(public_params)
    @walkin.restaurant_id = @restaurant.id
    @walkin.status = 'queuing'
    @walkin.queue_number = find_queue_number
    set_restaurant_queue
    set_walkin_user(@walkin)
    if @walkin.save!
      redirect_to restaurant_public_path(@restaurant)
    else
      render :new
    end
  end

  def public_new
    @walkin = Reservation.new
    render 'layouts/public_walkin_new', :layout => false
  end

  def public_show
    render 'layouts/public_walkin', :layout => false
  end

  def edit; end

  def show; end

  def update
    if @walkin.update(walkin_params)
      redirect_to restaurant_walkins_path(@restaurant)
    else
      render :edit
    end
  end

  def destroy
    @walkin.destroy
    redirect_to restaurant_walkins_path(@restaurant)
  end

  private

  def set_walkin_user(walkin)
    user = User.where(phone: walkin.phone)
    if user.count == 1
      walkin.user_id = user.pluck(:id)[0]
      walkin.name = user.pluck(:name)[0]
      walkin.email = user.pluck(:email)[0]
    # NEED TO CHECK IF CUSTOMER SUBMIT MULTIPLE TIMES --> Change!
    # elsif (user.count > 1 && walkin.phone)
    #   walkin.name = 'Walk in Customer (WARNING! Duplicate User number)'
    else
      walkin.name = 'Walk in Customer (Mobile Sign in)'
    end
  end

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def find_queue_number
    set_restaurant
    @restaurant.next_queue_number
  end

  def set_restaurant_queue
    set_restaurant
    @restaurant.next_queue_number += 1
    @restaurant.save
  end

  def set_walkin
    @walkin = Reservation.find(params[:id])
  end

  def public_params
    params.require(:reservation).permit(:phone, :party_size)
  end

  def walkin_params
    params.require(:reservation).permit(:name, :phone, :email, :party_size, :special_requests, :status)
  end
end
