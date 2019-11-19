class LightControl
  def initialize(gpio, options = {})
    raise 'nil gpio interace' if gpio.nil?

    @gpio                      = gpio
    @light_pin                 = options[:light_pin]                 || 8
    @relay_on_level            = options[:relay_on_level]            || :low
    @external_light_sensor     = options[:external_light_sensor]     || false
    @external_light_sensor_pin = options[:external_light_sensor_pin] || 10

    @gpio.set_numbering(:board)
    @gpio.setup(@light_pin, as: :output)

    @gpio.setup(@external_light_sensor_pin, as: :input) if @external_light_sensor

    @light_is_on = false

    @autumn_months = options[:autumn_months] || (9..11)
    @winter_months = options[:winter_months] || [12, 1, 2]
    @spring_months = options[:spring_months] || (3..5)
    @summer_months = options[:summer_months] || (6..8)

    @autumn_light_hours = options[:autumn_light_hours] || (6..20)
    @winter_light_hours = options[:winter_light_hours] || (6..20)
    @spring_light_hours = options[:spring_light_hours] || (6..20)
    @summer_light_hours = options[:summer_light_hours] || (6..20)
  end

  def tick
    light_needed? ? light_on : light_off
  end

  private

  def light_on
    return if @light_is_on

    @gpio.send("set_#{@relay_on_level}", @light_pin)
    @light_is_on = true
  end

  def light_off
    return unless @light_is_on

    off_level = :high
    off_level = :low if @relay_on_level == :high
    @gpio.send("set_#{off_level}", @light_pin)
    @light_is_on = false
  end

  def season(month)
    return :autumn if @autumn_months.include? month
    return :winter if @winter_months.include? month
    return :spring if @spring_months.include? month
    return :summer if @summer_months.include? month

    raise "month number: #{month} does not belong to any season defined in the options"
  end

  def light_hours(season)
    instance_variable_get("@#{season}_light_hours")
  end

  def enough_external_light?
    @gpio.high? @external_light_sensor_pin
  end

  def light_needed?(time = Time.now)
    needed = light_hours(season(time.month)).include? time.hour

    needed &= !enough_external_light? if @external_light_sensor

    needed
  end
end
