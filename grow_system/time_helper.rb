module TimeHelper
  def hours_diff(time_a = Time.now, time_b = Time.now)
    ((time_a - time_b) / 3_600).abs.to_i
  end
end
