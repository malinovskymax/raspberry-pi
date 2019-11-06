# Version 1.2.3

require 'rpi_gpio'

# settings
LIGHT_PIN      = 8
RELAY_ON_LEVEL = :low

AUTUMN_MONTHS = 9..11
WINTER_MONTHS = [12, 1, 2]
SPRING_MONTHS = 3..5
SUMMER_MONTHS = 6..8

AUTUMN_LIGHT_HOURS = [6, 7, 8, 9, 10, 11, 12, 17, 18, 19, 20]
WINTER_LIGHT_HOURS = 6..20
SPRING_LIGHT_HOURS = [6, 7, 8, 9, 10, 11, 12, 17, 18, 19, 20]
SUMMER_LIGHT_HOURS = [6, 7, 8, 9, 10, 20]
# settings end

RPi::GPIO.set_numbering :board

RPi::GPIO.setup LIGHT_PIN, as: :output

$light_is_on = false

def light_on
  return if $light_is_on

  RPi::GPIO.send("set_#{RELAY_ON_LEVEL}", LIGHT_PIN)
  $light_is_on = true
end

def light_off
  return unless $light_is_on

  off_level = :high
  off_level = :low if RELAY_ON_LEVEL == :high
  RPi::GPIO.send("set_#{off_level}", LIGHT_PIN)
  $light_is_on = false
end

def season(time)
  case time.month
  when AUTUMN_MONTHS
    :autumn
  when WINTER_MONTHS
    :winter
  when SPRING_MONTHS
    :spring
  when SUMMER_MONTHS
    :summer
  else
    raise "current month number: #{time.month} does not belong to any season defined in the `settings` section"
  end
end

def light_hours(season)
  Object.const_get("#{season}_LIGHT_HOURS".upcase)
end

def light_needed?(time = Time.now)
  light_hours(season(time)).include? time.hour
end

loop do
  light_needed? ? light_on : light_off

  sleep(1)
end
