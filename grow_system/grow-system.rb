require 'rpi_gpio'

require 'light_control'

light_controller = LightControl.new(RPi::GPIO)

loop do
  light_controller.tick

  sleep(1)
end
