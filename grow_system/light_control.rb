require_relative 'time_helper'

class LightControl
  include TimeHelper

  REACTION_ON_EXTERNAL_LIGHT_DELAY = 10 # seconds

  def initialize(gpio, options = {})
    raise 'nil gpio interace' if gpio.nil?

    @gpio                      = gpio
    @light_pin                 = options[:light_pin]                 || 8
    @relay_on_level            = options[:relay_on_level]            || :low
    @external_light_sensor     = options[:external_light_sensor]     || false
    @external_light_sensor_pin = options[:external_light_sensor_pin] || 10

    if options[:diagnose].is_a? Hash
      @diagnose = options[:diagnose][:enabled]
      @diagnose_options = { abnormal_phase_duration: options[:diagnose][:abnormal_phase_duration] }
    else
      @diagnose = false
    end

    @telegram_reporter        = options[:telegram_reporter]        || false
    @daily_telegram_report    = options[:daily_telegram_report]    || false
    @resend_telegram_alert_in = options[:resend_telegram_alert_in] || 6 # hours

    @gpio.set_numbering(:board)
    @gpio.setup(@light_pin, as: :output)

    @gpio.setup(@external_light_sensor_pin, as: :input) if @external_light_sensor

    @light_is_on = false

    @daily_report = []

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
    light_needed = light_needed?

    diagnose(light_needed) if @diagnose

    if @telegram_reporter && @daily_telegram_report
      collect_daily_report_data(light_needed)
      send_daily_teleram_report
    end

    light_needed ? light_on : light_off
  end

  private

  def collect_daily_report_data(light_needed)
    return if light_needed == @light_is_on

    report = <<~EOS
    Event timestamp: #{Time.now}
    Light turned #{light_needed ? 'on' : 'off'}
    EOS
    report += "External light sensor #{enough_external_light? ? 'detects' : 'does not detect'} enough light\n" if @external_light_sensor
    @daily_report << report
  end

  def send_daily_teleram_report
    @daily_report_start ||= Time.now.day

    day_now = Time.now.day

    return if day_now == @daily_report_start

    @telegram_reporter.send_report(kind: 'daily', text: @daily_report.join("\n"))
    @daily_report_start = day_now
    @daily_report = []
  end

  def send_telegram_alert(text)
    @telegram_reporter.send_report(kind: 'alert', text: text)
  end

  def diagnose(light_is_on)
    @light_switched_at ||= Time.now

    now = Time.now
    alerts = {}

    if @light_is_on != light_is_on
      @light_switched_at = now
    else
      if hours_diff(now, @light_switched_at) >= @diagnose_options[:abnormal_phase_duration]
        alerts[:light_mode_stuck] = <<~EOS
        Light has been #{@light_is_on ? 'on' : 'off'} from #{@light_switched_at} to #{now}
        Abnormal phase duration is #{@diagnose_options[:abnormal_phase_duration]} hours
        Problem detected at #{now}
        EOS
      end
    end

    send_alerts(alerts)
  end

  def send_alerts(alerts)
    @alerts_sent_at ||= {}
    now = Time.now
    blinked = false

    alerts.each_pair do |key, text|
      if @telegram_reporter
        if @alerts_sent_at[key].nil? || hours_diff(@alerts_sent_at[key], now) >= @resend_telegram_alert_in
          @alerts_sent_at[key] = now
          text = "Resending:\n#{text}" if @alerts_sent_at[key]
          send_telegram_alert(text)
        end
      else
        send_gpio_light_blink unless blinked
      end
    end
  end

  def light_on
    return if @light_is_on

    send_gpio_light_on
    @light_is_on = true
  end

  def light_off
    return unless @light_is_on

    send_gpio_light_off
    @light_is_on = false
  end

  def send_gpio_light_on
    @gpio.send("set_#{@relay_on_level}", @light_pin)
  end

  def send_gpio_light_off
    off_level = :high
    off_level = :low if @relay_on_level == :high
    @gpio.send("set_#{off_level}", @light_pin)
  end

  def send_gpio_light_blink
    send_gpio_light_off
    sleep(0.5)
    send_gpio_light_on
    sleep(0.5)
    send_gpio_light_off
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
    enough_light = @gpio.low? @external_light_sensor_pin
    if enough_light
      sleep(REACTION_ON_EXTERNAL_LIGHT_DELAY)
      enough_light = @gpio.low? @external_light_sensor_pin
    end

    enough_light
  end

  def light_needed?(time = Time.now)
    needed = light_hours(season(time.month)).include? time.hour

    needed &= !enough_external_light? if @external_light_sensor

    needed
  end
end
