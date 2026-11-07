class EventsController < ApplicationController
  before_action :authenticate_user!

  def index
    @events = current_user.events
  end

  def show
    @event = current_user.events.find(params[:id])
    @santa_participation = @event.participations.find_by(user: current_user)
    @giftee_participation = @event.participations.find_by(giftee: current_user)
  end

  def new
    @event = Event.new
  end

  def create
    @event = current_user.organized_events.build(event_params)
    if @event.save
      redirect_to @event, notice: "Игра создана"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def draw
    @event = current_user.organized_events.find(params[:id])
    @event.draw!
    redirect_to @event, notice: "Жеребьёвка проведена"
  rescue Event::DrawError => e
    redirect_to @event, alert: e.message
  end

  def destroy
    @event = current_user.organized_events.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_path, notice: "Игра удалена", status: :see_other }
      format.turbo_stream { redirect_to events_path, notice: "Игра удалена", status: :see_other }
    end
  end

  private

  def event_params
    params.require(:event).permit(:name, :description, :budget, :exchange_date)
  end
end
