class HomeController < ApplicationController
  def index
  end

  def set_session
    session[:theme] = params[:favorite_color]
    logger.info "In set session: #{params[:favorite_color]}"
    redirect_to root_path
  end
end
