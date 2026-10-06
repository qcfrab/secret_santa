class WishesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wish, only: %i[show edit update destroy]

  def index
    @wishes = current_user.wishes
  end

  def show
  end

  def new
    @wish = current_user.wishes.build
  end

  def edit
  end

  def create
    @wish = current_user.wishes.build(wish_params)
    if @wish.save
      redirect_to wishes_path, notice: "Желание добавлено"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @wish.update(wish_params)
      redirect_to wishes_path, notice: "Желание обновлено"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wish.destroy
    redirect_to wishes_path, notice: "Желание удалено", status: :see_other
  end

  private

  def set_wish
    @wish = current_user.wishes.find(params[:id])
  end

  def wish_params
    params.require(:wish).permit(:title, :description, :url)
  end
end