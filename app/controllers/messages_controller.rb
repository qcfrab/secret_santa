class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_assignment

  def create
    @message = @assignment.messages.build(message_params)
    @message.from_santa = (current_user.id == @assignment.santa.id)

    if @message.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @assignment }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to @assignment }
      end
    end
  end

  private

  def set_assignment
    if params[:assignment_id]
      @assignment = Assignment.find(params[:assignment_id])
    elsif params[:participation_id]
      participation = Participation.find(params[:participation_id])
      if participation.user_id == current_user.id
        @assignment = participation.assignment_as_santa || participation.assignment_as_giftee
      elsif participation.assignment_as_santa&.giftee&.id == current_user.id
        @assignment = participation.assignment_as_santa
      elsif participation.assignment_as_giftee&.santa&.id == current_user.id
        @assignment = participation.assignment_as_giftee
      end
      raise ActiveRecord::RecordNotFound unless @assignment
    else
      raise ActiveRecord::RecordNotFound
    end

    raise ActiveRecord::RecordNotFound unless @assignment.participant?(current_user)
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
