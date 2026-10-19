class WishesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wish, only: %i[show edit update destroy]

  PER_PAGE = 6

  def index
    scope = defined?(current_user) && current_user ? current_user.wishes.order(created_at: :desc) : Wish.order(created_at: :desc)

    @page = [params.fetch(:page, 1).to_i, 1].max
    @total_count = scope.count
    @total_pages = [(@total_count.to_f / PER_PAGE).ceil, 1].max
    @page = @total_pages if @page > @total_pages

    @wishes = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
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
    params.require(:wish).permit(:title, :description, :url, :image)
  end
end