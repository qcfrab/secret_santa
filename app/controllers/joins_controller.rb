class JoinsController < ApplicationController
  def show;   @event = Event.find_by!(invite_code: params[:code]); end
  def create
    event = Event.find_by!(invite_code: params[:code])
    event.join(current_user) ? redirect_to(event, notice: "Вы в игре!") : redirect_to(root_path, alert: "Игра уже началась")
  end
end
