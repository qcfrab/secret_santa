class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    participation = Participation.where(user: current_user).or(Participation.where(giftee: current_user)).find(params[:participation_id])
    message = participation.messages.build(message_params)
    message.from_santa = (current_user.id == participation.user_id)
    message.save
    redirect_to participation
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
