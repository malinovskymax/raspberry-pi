require 'rpi_gpio'

LIGHT_PIN = 8

SUMMER_MONTHS      = 6..8
WINTER_LIGHT_HOURS = 7..21

RPi::GPIO.set_numbering :board

RPi::GPIO.setup LIGHT_PIN, as: :output

def light_on
  RPi::GPIO.set_high LIGHT_PIN
end

def light_off
  RPi::GPIO.set_low LIGHT_PIN
end

def season(time = Time.now)
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

def light_needed?(time)
  light_hours(season(time)).include? time.hour
end

loop do
  if light_needed?(Time.now)
    light_on
  else
    light_off
  end

  sleep(1000)
end
