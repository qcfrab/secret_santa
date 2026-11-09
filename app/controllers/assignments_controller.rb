class AssignmentsController < ApplicationController
  before_action :authenticate_user!

  def show
    @assignment = Assignment.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @assignment.participant?(current_user)

    @messages = @assignment.messages.order(:created_at)
    @message = Message.new
  end
end
