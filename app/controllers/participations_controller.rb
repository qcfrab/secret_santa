class ParticipationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @participation = Participation.find(params[:id])
    assignment = if @participation.user_id == current_user.id
                   @participation.assignment_as_santa || @participation.assignment_as_giftee
                 elsif @participation.assignment_as_santa&.giftee&.id == current_user.id
                   @participation.assignment_as_santa
                 elsif @participation.assignment_as_giftee&.santa&.id == current_user.id
                   @participation.assignment_as_giftee
                 end

    raise ActiveRecord::RecordNotFound unless assignment&.participant?(current_user)

    redirect_to assignment_path(assignment)
  end
end
