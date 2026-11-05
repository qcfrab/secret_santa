class ParticipationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @participation = Participation.where(user: current_user).or(Participation.where(giftee: current_user)).find(params[:id])
    @messages = @participation.messages.order(:created_at)
    @message = Message.new
  end
end
