class AdminController < ApplicationController
  before_action :authenticate_user!, :admins_only

  def home
  end

  def tags
  end

  def stats
    @page = params.fetch('page', 1)
  end
end
