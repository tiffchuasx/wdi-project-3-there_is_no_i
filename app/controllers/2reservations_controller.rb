class ReservationsController < ApplicationController
  before_action :set_restaurant, only: %i[new index show create edit update destroy]
  before_action :set_reservation, only: %i[show edit update destroy]
  # helper ReservationsHelper

  def index
    @reservations = Reservation.where(restaurant_id: params[:restaurant_id]).order('start_time ASC')
  end

  def create
    d = Time.parse(params[:reservation][:date])
    date = d.strftime("%Y-%m-%d")
    puts "DATE #{date}"
    day = d.strftime('%d')
    month = d.strftime('%m')
    year = d.strftime('%Y')
    t = Time.parse(params[:reservation][:time])
    r_start_time = t.change(day: day, month: month, year: year, offset: +0o000) + 8.hours
    puts "START TIME: #{r_start_time}"
    r_end_time = r_start_time + 2.hours
    party_size = params[:reservation][:party_size]

    # find all tables (to be refactored into another function)
    @avail_tables = Table.where(restaurant_id: @restaurant.id).where('capacity_current = ?', 0)

    # find all reservations from that restaurant on the date chosen by customer on the reservation form
    all_reservations = Reservation.where(restaurant_id: params[:restaurant_id]).where("DATE(start_time) = ?", date)

    # find all reservations that have tables which CANNOT be booked
    all_unavail_reservations = all_reservations.where("start_time < ?", r_end_time).or(all_reservations.where("end_time > ?", r_start_time)).to_a
    puts "ALL UNAVAIL RESERVATIONS #{all_unavail_reservations}"

    unavail_tables = []
    all_unavail_reservations.each do |reservation|
      unavail_tables.push(Table.where("id = ?", reservation.table_id))
    end

    if unavail_tables.length > 0
      unavail_tables.map do |table|
        table.id
      end
    end

    # remove table ids of unavailable tables from available tables
    avail_tables.select do |table|
      unavail_tables.exclude?(table[:id])
    end

    # filter tables by appropriate capacity
    table_array = []
    avail_tables.each do |reservation|
      table_array.push(Table.where("id = ?", reservation.table_id).where("capacity_total >= ?", reservation.party_size))
    end

    # sort tables in the table array by their capacity_total
    table_array.sort_by! { |table| table.capacity_total }

    # [0] of this array will give the table with the minimally adequate capacity to fit all customers
    @chosen_table = table_array[0]

    # if-else statement to reject reservation in the event that there are no available tables
    if all_avail_reservations.length == 0
      before_avail_reservations = all_reservations.where("start_time >= ?", r_end_time - 1.hours).or(all_reservations.where("end_time <= ?", r_start_time - 1.hours)).to_a
      before_table_array = []
      before_avail_reservations.each do |reservation|
        before_table_array.push(Table.where("id = ?", reservation.table_id).where("capacity_total >= ?", reservation.party_size))
      end
      before_table_array.sort_by! { |table| table.capacity_total }
      before_chosen_table = before_table_array[0]

      after_avail_reservations = all_reservations.where("start_time >= ?", r_end_time + 1.hours).or(all_reservations.where("end_time <= ?", r_start_time + 1.hours)).to_a
      after_table_array = []
      after_avail_reservations.each do |reservation|
        after_table_array.push(Table.where("id = ?", reservation.table_id).where("capacity_total >= ?", reservation.party_size))
      end
      after_table_array.sort_by! { |table| table.capacity_total }
      after_chosen_table = after_table_array[0]
    else
      # find the tables by table_id in the reservation that have a capacity >= party size
      table_array = []
      all_avail_reservations.each do |reservation|
        table_array.push(Table.where("id = ?", reservation.table_id).where("capacity_total >= ?", reservation.party_size))
      end

      # sort tables in the table array by their capacity_total
      table_array.sort_by! { |table| table.capacity_total }

      # [0] of this array will give the table with the minimally adequate capacity to fit all customers
      the_chosen_table = table_array[0]

      new_res = {}
      new_res[:name] = params[:reservation][:name]
      new_res[:phone] = params[:reservation][:phone]
      new_res[:start_time] = r_start_time
      new_res[:end_time] = r_start_time + 2.hours
      new_res[:table_id] = the_chosen_table.table_id
      new_res[:party_size] = params[:reservation][:party_size]
      new_res[:restaurant_id] = params[:restaurant_id]

      @reservation = Reservation.new(new_res)

      if @reservation.save
        redirect_to restaurant_path(params[:restaurant_id])
      else
        render :new
      end
    end
  end

  def edit
  end

  def new
  end

  def show
  end

  def update
    if @reservation.update(reservation_params)
      redirect_to restaurant_reservations_path(@restaurant)
    else
      render :edit
    end
  end

  def destroy
    @reservation.destroy
    redirect_to restaurant_reservations_path(@restaurant)
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(:name, :party_size, :start_time)
  end
end