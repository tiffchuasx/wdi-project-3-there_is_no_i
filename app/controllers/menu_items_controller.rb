class MenuItemsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_restaurant, only: [:index, :create, :edit, :update, :destroy]
  before_action :set_menu_item, only: [:edit, :show, :update, :destroy]
  before_action :authenticate_restaurant_user, except: [:index, :show]
  helper MenuItemsHelper

  def index
    @menu_items = MenuItem.where(restaurant_id: params[:restaurant_id]).order('LOWER(name) ASC')
  end

  def create
    @menu_item = MenuItem.new(menu_item_params)
    @menu_item.restaurant_id = @restaurant.id
    if @menu_item.save!
      redirect_to restaurant_menu_items_path(@restaurant)
    else
      render :new
    end
  end

  def new
    @menu_item = MenuItem.new
  end

  def edit
  end

  def show
  end

  def update
    if @menu_item.update(menu_item_params)
      redirect_to restaurant_menu_items_path(@restaurant)
    else
      render :edit
    end
  end

  def destroy
    @menu_item.destroy
    redirect_to restaurant_menu_items_path(@restaurant)
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_menu_item
    @menu_item = MenuItem.find(params[:id])
  end

  def menu_item_params
    params.require(:menu_item).permit(:name, :price, :description, :ingredients, :tags)
  end

  def authenticate_restaurant_user
    flash['alert'] = 'You do not have permission to access that page'
    redirect_to restaurants_path if current_user[:restaurant_id] != @restaurant[:id]
  end
end
