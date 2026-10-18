class EventsController < ApplicationController
  before_action :authenticate_user!

  def index
    @events = current_user.events
  end

  def show
    @event = current_user.events.find(params[:id])
    @santa_assignment = @event.assignments.find_by(santa: current_user)
    @giftee_assignment = @event.assignments.find_by(giftee: current_user)
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

  private

  def event_params
    params.require(:event).permit(:name, :description, :budget, :exchange_date)
  end
end