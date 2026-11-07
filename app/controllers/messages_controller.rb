class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @participation = Participation.where(user: current_user)
                                  .or(Participation.where(giftee: current_user))
                                  .find(params[:participation_id])
    @message = @participation.messages.build(message_params)
    @message.from_santa = (current_user.id == @participation.user_id)

    if @message.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @participation }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to @participation }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
