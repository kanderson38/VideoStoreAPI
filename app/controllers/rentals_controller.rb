# frozen_string_literal: true

class RentalsController < ApplicationController
  def checkout
    rental = Rental.new(movie_id: params[:rental][:movie_id], customer_id: params[:rental][:customer_id], checkout_date: Date.today, due_date: (Date.today + 7))
    movie = Movie.find_by(id: rental.movie_id)
    if movie.available_inventory == 0
      render json: { ok: false, message: 'Not enough copies in inventory' }, status: :bad_request
      return
    else
      movie.available_inventory -= 1
    end

    if rental.save
      movie.save
      customer = Customer.find_by(id: rental.customer_id)
      customer.movies_checked_out_count += 1
      customer.save
      render status: :ok
    else
      render json: { ok: false, message: rental.errors.messages }, status: :bad_request
    end
  end

  def checkin
    rental = Rental.where(['movie_id = ? and customer_id = ? and checked_in = ?', params[:rental][:movie_id], params[:rental][:customer_id], false]).first

    customer = Customer.find_by(id: params[:rental][:customer_id])
    movie = Movie.find_by(id: params[:rental][:movie_id])
    rental.checked_in = true
    if rental.save
      customer.movies_checked_out_count -= 1
      customer.save
      movie.available_inventory += 1
      movie.save
      render status: :ok
      return
    else
      render json: { ok: false, message: rental.errors.messages }, status: :bad_request
    end
  end

  private

  def rental_params
    params.require(:rental).permit(:movie_id, :customer_id)
  end
end
