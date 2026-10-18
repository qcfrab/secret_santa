class MessagesController < ApplicationController
  def create
    assignment = Assignment.where(santa: current_user).or(Assignment.where(giftee: current_user)).find(params[:assignment_id])
    message = assignment.messages.build(params.require(:message).permit(:body).merge(sender: current_user))
    message.save
    redirect_to assignment
  end
end
