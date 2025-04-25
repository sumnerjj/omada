class MembersController < ApplicationController
  def dashboard
    @member = Member.find(params[:id])
    now = Time.zone.now

    # — Last 7 days window
    week_end   = now.end_of_day
    week_start = now.beginning_of_day - 6.days
    prev_week_start = week_start - 7.days
    prev_week_end   = week_start - 1.second

    week_scope      = @member.continuous_glucose_levels.where(tested_at: week_start..week_end)
    prev_week_scope = @member.continuous_glucose_levels.where(tested_at: prev_week_start..prev_week_end)

    # — This month window
    month_start      = now.beginning_of_month.beginning_of_day
    month_end        = now.end_of_month.end_of_day
    prev_month_start = month_start.prev_month.beginning_of_month.beginning_of_day
    prev_month_end   = month_start.prev_month.end_of_month.end_of_day

    month_scope      = @member.continuous_glucose_levels.where(tested_at: month_start..month_end)
    prev_month_scope = @member.continuous_glucose_levels.where(tested_at: prev_month_start..prev_month_end)

    @metrics = {
      last_7_days:      calculate_metrics(week_scope,      prev_week_scope),
      current_month:    calculate_metrics(month_scope,     prev_month_scope)
    }
  end

  private

  def calculate_metrics(current_scope, prior_scope)
    curr_count = current_scope.count.to_f
    prior_count = prior_scope.count.to_f

    avg_curr  = current_scope.average(:value)&.to_f
    avg_prior = prior_scope.average(:value)&.to_f

    pct_above_curr  = curr_count > 0 ? (current_scope.where("value > ?", 180).count / curr_count * 100) : 0
    pct_above_prior = prior_count > 0 ? (prior_scope.where("value > ?", 180).count / prior_count * 100) : 0

    pct_below_curr  = curr_count > 0 ? (current_scope.where("value < ?", 70).count / curr_count * 100) : 0
    pct_below_prior = prior_count > 0 ? (prior_scope.where("value < ?", 70).count / prior_count * 100) : 0

    {
      average:                   avg_curr&.round(1),
      average_change:            avg_curr && avg_prior ? (avg_curr - avg_prior).round(1) : nil,
      time_above_range:          pct_above_curr.round(1),
      time_above_range_change:   (pct_above_curr - pct_above_prior).round(1),
      time_below_range:          pct_below_curr.round(1),
      time_below_range_change:   (pct_below_curr - pct_below_prior).round(1)
    }
  end
end
