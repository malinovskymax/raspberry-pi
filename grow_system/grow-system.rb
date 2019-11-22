Dir.foreach("#{__dir__}/libs/ruby/2.6.0/gems") { |d| $: << "#{__dir__}/libs/ruby/2.6.0/gems/#{d}/lib" }

$: << __dir__

require 'rpi_gpio'
require 'light_control'

# Dummy wait for network hack
require 'net/http'
retries = 0
begin
  Net::HTTP.get('example.com', '/')
rescue Exception => e
  if retries < 5
    sleep(retries += 1)
    retry
  else
    raise e
  end
end
retries = nil

options = {}

if ENV['TELEGRAM_BOT_API_TOKEN']
  require 'telegram_bot_connector'

  options[:telegram_reporter] = TelegramBotConnector.new(ENV['TELEGRAM_BOT_API_TOKEN'])
end

options[:diagnose] = { enabled: true, abnormal_phase_duration: 14 }
options[:external_light_sensor] = true
options[:daily_telegram_report] = true

light_controller = LightControl.new(RPi::GPIO, options)

loop do
  light_controller.tick

  sleep(1)
end
