class InvoicesController < ApplicationController
  include AuthenticateRestaurantUser
  include SendEmail
  before_action :authenticate_user!, except: [:create]
  before_action :set_restaurant_id
  before_action :set_invoice, only: [:edit, :show, :update, :destroy]
  before_action :check_user_is_part_of_restaurant, except: [:create, :show]
  before_action :check_user_is_part_of_invoice, only: [:show]
  helper InvoicesHelper

  def index
    add_breadcrumb "Restaurants", :restaurants_path
    add_breadcrumb "Back to restaurant", restaurant_path(@restaurant)
    gon.restaurant = @restaurant
    @invoices = Invoice.where(restaurant_id: params[:restaurant_id])
  end

  def create
    # pay for takeaway
    if params[:is_take_away]
      :pay_with_stripe
    end

    if params[:order] && params[:order]["time(1i)"]
      @takeaway_time = Time.zone.local( params[:order]["time(1i)"].to_i, params[:order]["time(2i)"].to_i, params[:order]["time(3i)"].to_i, params[:order]["time(4i)"].to_i, params[:order]["time(5i)"].to_i, 0)
    end

    # check if invoice exists
    if params[:invoice_id]
      @invoice = Invoice.find(params[:invoice_id])
    # check if takeaway
    elsif params[:is_take_away] == "true"
      @invoice = Invoice.new(restaurant_id: @restaurant.id, user_id: current_user.id, user_name: current_user.name, takeaway_time: @takeaway_time)
    # check if reservation or queuing
    elsif params[:reservation_id]
      @invoice = Invoice.new(restaurant_id: @restaurant.id, user_id: current_user.id, user_name: current_user.name, reservation_id: params[:reservation_id])
    # new restaurant order
    else
      @invoice = Invoice.new(restaurant_id: @restaurant.id, table_id: params[:table_id])
    end

    if @invoice.save!
      orders = params[:orders].split('/')

    # action cable the orders to /orders
      orders.each do |menu_item|
        @order = Order.create(user_id: current_user.id, is_take_away: params[:is_take_away], invoice_id: @invoice.id, menu_item_id: menu_item, request_description: params[:request])
        ActionCable.server.broadcast('room_channel', {invoice: @invoice.id, received: @order.created_at, item: @order.menu_item.name, is_take_away: params[:is_take_away], restaurant: @restaurant.id, request_description: params[:request]})
      end

      # send takeaway user a confirmation email
      if params[:is_take_away] == "true"
        body = "Dear #{current_user.name},\nYour takeaway order ID:#{@invoice.id} at #{@restaurant.name} for #{@takeaway_time} has been received.\nThank you and see you soon! \n \n \nPowered by Locavorus"
        send_email(current_user.name, current_user.email, @restaurant.name, body)
        flash[:notice] = "Thanks for ordering takeaway. You should receive an email confirmation of your order soon."
        redirect_to invoices_path
      # reservation/queuing order confirmation
      elsif params[:reservation_id]
        flash[:notice] = "Your order has been added to your reservation."
        redirect_to reservations_path
      # restaurant add to order confirmation
      elsif params[:invoice_id]
        flash[:notice] = "Added to order."
        redirect_to dashboard_path
      # restaurant new order confirmation
      else
        flash[:notice] = "Order created."
        redirect_to dashboard_path
      end
    else
      flash[:alert] = "There was an error submitting your order. Please try again."
      redirect_to restaurant_menu_items_path(@restaurant)
    end
  end

  def edit
    @table_options = @restaurant.tables.map do |table|
      [table.name, table.id]
    end
  end

  def show
  end

  def update
    # invoice - complete action
    if params[:time_end] == ''
      if @invoice.update(time_end: DateTime.now)
        flash[:notice] = 'Invoice successfully updated'
      else
        flash[:alert] = 'There was a problem updating the invoice. Please try again.'
      end
      redirect_to restaurant_invoices_path(@restaurant)
    # invoice - pay and complete action
    elsif params[:stripeToken]
      :payWithStripe
      @x = User.where(email: params[:stripeEmail]).count > 0 ? User.where(email: params[:stripeEmail]).first.id : nil

      if @invoice.update(time_end: DateTime.now, user_id: @x)
        flash[:notice] = 'Invoice successfully updated.'
      else
        flash[:alert] = 'There was a problem updating the invoice. Please try again.'
      end
      redirect_to restaurant_invoices_path(@restaurant)
    # invoice - update action
    else
      if @invoice.update(invoice_params)
        flash[:notice] = 'Invoice successfully updated'
        redirect_to restaurant_invoices_path(@restaurant)
      else
        flash[:alert] = 'There was a problem updating the invoice. Please try again.'
        render :edit
      end
    end
  end

  def destroy
    @invoice.destroy
    redirect_to restaurant_invoices_path(@restaurant)
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(:user_name, :table_id, :time_end, :takeaway_time)
  end

  def check_user_is_part_of_invoice
    if current_user[:id] != @invoice[:user_id] && !current_user.restaurants.include?(@invoice.restaurant)
      flash['alert'] = 'You do not have permission to access that page'
      redirect_to edit_user_registration_path
    end
  end

  def pay_with_stripe
    # convert amount in dollars to amount in cents
    @amount = params[:total_price].to_f
    @amount = (@amount * 100).to_i

    begin
      customer = Stripe::Customer.create(
      :email => params[:stripeEmail],
      :source => params[:stripeToken]
      )
      charge = Stripe::Charge.create(
      :customer => customer.id,
      :amount => @amount,
      :description => "Invoice:#{@invoice.id}",
      :currency => 'SGD'
      )
    rescue Stripe::CardError => e
      flash[:alert] = e.message
      redirect_to restaurant_menu_items_path(@restaurant)
    end
  end
end
