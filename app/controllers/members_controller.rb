class MembersController < ApplicationController
    def dashboard
      @member = Member.find(params[:id])
      @glucose_levels = @member.continuous_glucose_levels.order(tested_at: :desc)
  
      @stats = {
        count: @glucose_levels.count,
        average: @glucose_levels.average(:value)&.round(1),
        min: @glucose_levels.minimum(:value),
        max: @glucose_levels.maximum(:value),
        latest: @glucose_levels.first
      }
    end
  end
  