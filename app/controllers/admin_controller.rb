class AdminController < ApplicationController
  before_filter :authenticate_user!, :admins_only

  def home
  end

  def clear_cache
    Rails.cache.clear
    redirect_to admin_path, notice: "Cache was successfully cleared."
  end

  def tags
  end
end
