class GlucoseStatsCalculator
  def self.call(current_scope, prior_scope)
    curr_count = current_scope.count.to_f
    prior_count = prior_scope.count.to_f

    avg_curr = current_scope.average(:value)&.to_f
    avg_prior = prior_scope.average(:value)&.to_f

    pct_above_curr = curr_count > 0 ? (current_scope.where("value > 180").count / curr_count * 100) : 0
    pct_above_prior = prior_count > 0 ? (prior_scope.where("value > 180").count / prior_count * 100) : 0

    pct_below_curr = curr_count > 0 ? (current_scope.where("value < 70").count / curr_count * 100) : 0
    pct_below_prior = prior_count > 0 ? (prior_scope.where("value < 70").count / prior_count * 100) : 0

    {
      average: avg_curr&.round(1),
      average_change: avg_curr && avg_prior ? (avg_curr - avg_prior).round(1) : nil,
      time_above_range: pct_above_curr.round(1),
      time_above_range_change: (pct_above_curr - pct_above_prior).round(1),
      time_below_range: pct_below_curr.round(1),
      time_below_range_change: (pct_below_curr - pct_below_prior).round(1),
    }
  end
end
