class AssignmentsController < ApplicationController
  def show
    @assignment = Assignment.where(santa: current_user).or(Assignment.where(giftee: current_user)).find(params[:id])
    @messages = @assignment.messages.order(:created_at)
    @message = Message.new
  end
end
