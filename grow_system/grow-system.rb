# Version 1.1.1

require 'rpi_gpio'

# settings
LIGHT_PIN      = 8
RELAY_ON_LEVEL = :low

SUMMER_MONTHS      = 6..8
WINTER_LIGHT_HOURS = 7..21
SUMMER_LIGHT_HOURS = [7, 8, 9, 10, 11, 12, 13, 20, 21]
# settings end

RPi::GPIO.set_numbering :board

RPi::GPIO.setup LIGHT_PIN, as: :output

def light_on
  RPi::GPIO.send("set_#{RELAY_ON_LEVEL}", LIGHT_PIN)
end

def light_off
  off_level = :high
  off_level = :low if RELAY_ON_LEVEL == :high
  RPi::GPIO.send("set_#{off_level}", LIGHT_PIN)
end

def season(time)
  case time.month
  when SUMMER_MONTHS
    :summer
  else
    :winter
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

  sleep(1000)
end
