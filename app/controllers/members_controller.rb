# app/controllers/members_controller.rb
class MembersController < ApplicationController
  def dashboard
    @member = Member.find(params[:id])
    now = Time.zone.now

    # build the same window endpoints in zone-aware UTC
    week_start = (now.beginning_of_day - 6.days).utc
    week_end = now.end_of_day.utc
    prev_week_start = (week_start - 7.days)
    prev_week_end = (week_start - 1.second)

    month_start = now.beginning_of_month.beginning_of_day.utc
    month_end = now.end_of_month.end_of_day.utc
    prev_month_start = (month_start - 1.month).beginning_of_month
    prev_month_end = (month_start - 1.month).end_of_month.end_of_day

    week_scope = @member.continuous_glucose_levels.where(tested_at: week_start..week_end)
    prev_week_scope = @member.continuous_glucose_levels.where(tested_at: prev_week_start..prev_week_end)

    month_scope = @member.continuous_glucose_levels.where(tested_at: month_start..month_end)
    prev_month_scope = @member.continuous_glucose_levels.where(tested_at: prev_month_start..prev_month_end)

    @metrics = {
      last_7_days: GlucoseStatsCalculator.call(week_scope, prev_week_scope),
      current_month: GlucoseStatsCalculator.call(month_scope, prev_month_scope),
    }
  end

  def metrics
    member = Member.find(params[:id])
    timeframe = params[:timeframe]

    now = Time.zone.now

    # Setup date ranges
    week_start = (now.beginning_of_day - 6.days).utc
    week_end = now.end_of_day.utc
    prev_week_start = week_start - 7.days
    prev_week_end = week_start - 1.second

    month_start = now.beginning_of_month.beginning_of_day.utc
    month_end = now.end_of_month.end_of_day.utc
    prev_month_start = (month_start - 1.month).beginning_of_month
    prev_month_end = (month_start - 1.month).end_of_month.end_of_day

    case timeframe
    when "last_7_days"
      current_scope = member.continuous_glucose_levels.where(tested_at: week_start..week_end)
      prior_scope = member.continuous_glucose_levels.where(tested_at: prev_week_start..prev_week_end)
    when "current_month"
      current_scope = member.continuous_glucose_levels.where(tested_at: month_start..month_end)
      prior_scope = member.continuous_glucose_levels.where(tested_at: prev_month_start..prev_month_end)
    else
      return render json: { error: "Invalid timeframe" }, status: :unprocessable_entity
    end

    metrics = GlucoseStatsCalculator.call(current_scope, prior_scope)

    render json: {
      member_id: member.id,
      timeframe: timeframe,
      metrics: metrics,
    }
  end
end
