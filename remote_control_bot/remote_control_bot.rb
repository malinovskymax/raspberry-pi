Dir.foreach("#{__dir__}/libs/ruby/2.6.0/gems") { |d| $: << "#{__dir__}/libs/ruby/2.6.0/gems/#{d}/lib" }

require 'json'
require 'telegram/bot'

token = ENV['TELEGRAM_BOT_API_TOKEN']
password = ENV['TELEGRAM_BOT_PASSWORD']
user_name = ENV['REMOTE_CONTROL_BOT_USER_NAME'] || 'pi'

raise 'token or (and) password is not set' if token.nil? || password.nil?

AVAILABLE_COMMANDS = ['reboot',
                      'log',
                      'own log',
                      'clear log',
                      'clear own log',
                      'shutdown',
                      'pull code',
                      'subscribe',
                      'unsubscribe',
                      'any other to display this help']
GROW_LOG = ENV['GROW_LOG'] || "#{__dir__}/../../grow_log"
OWN_LOG = "#{__dir__}/log"

SUBSCRIBERS_FILE = "#{__dir__}/../.telegram_subscribers.json"

def subscribers
  if File.exist?(SUBSCRIBERS_FILE) && File.file?(SUBSCRIBERS_FILE)
    return JSON.parse(File.open(SUBSCRIBERS_FILE, 'r') { |f| f.read })['subscribers']
  end

  return []
end

confirmation_codes = {}

def confirmation_code
  "#{rand(9)}#{rand(9)}#{rand(9)}"
end

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

Telegram::Bot::Client.run(token) do |bot|
  
  bot.listen do |message|
    confirmation_codes[message.chat.id] = confirmation_code if message.text =~ /.+\s#{password}$/i

    begin
      # reboot
      if message.text =~ /^reboot\s#{password}$/i
        bot.api.send_message(chat_id: message.chat.id, text: "Send 'reboot #{confirmation_codes[message.chat.id]}' to confirm")
      elsif confirmation_codes[message.chat.id] && message.text =~ /^reboot\s#{confirmation_codes[message.chat.id]}/i
        bot.api.send_message(chat_id: message.chat.id, text: 'Rebooting')
        `reboot`
      # log
      elsif message.text =~ /^log\s#{password}$/i
        bot.api.send_message(chat_id: message.chat.id, text: "Send 'log #{confirmation_codes[message.chat.id]}' to confirm")
      elsif confirmation_codes[message.chat.id] && message.text =~ /^log\s#{confirmation_codes[message.chat.id]}$/i
        confirmation_codes.delete(message.chat.id)
        log = `tail -n 50 #{GROW_LOG}`
        bot.api.send_message(chat_id: message.chat.id, text: "#{GROW_LOG}:\n#{log}")
      # own log
      elsif message.text =~ /^own\slog\s#{password}$/i
        bot.api.send_message(chat_id: message.chat.id, text: "Send 'own log #{confirmation_codes[message.chat.id]}' to confirm")
      elsif confirmation_codes[message.chat.id] && message.text =~ /^own\slog\s#{confirmation_codes[message.chat.id]}$/i
        confirmation_codes.delete(message.chat.id)
        log = `tail -n 50 #{OWN_LOG}`
        bot.api.send_message(chat_id: message.chat.id, text: "#{OWN_LOG}:\n#{log}")
      # clear log
      elsif message.text =~ /^clear\slog\s#{password}$/i
        bot.api.send_message(chat_id: message.chat.id, text: "Send 'clear log #{confirmation_codes[message.chat.id]}' to confirm")
      elsif confirmation_codes[message.chat.id] && message.text =~ /^clear\slog\s#{confirmation_codes[message.chat.id]}$/i
        confirmation_codes.delete(message.chat.id)
        log = `echo '' > #{GROW_LOG}`
        bot.api.send_message(chat_id: message.chat.id, text: "#{GROW_LOG} cleared")
      # clear own log
      elsif message.text =~ /^clear\sown\slog\s#{password}$/i
        bot.api.send_message(chat_id: message.chat.id, text: "Send 'clear own log #{confirmation_codes[message.chat.id]}' to confirm")
      elsif confirmation_codes[message.chat.id] && message.text =~ /^clear\sown\slog\s#{confirmation_codes[message.chat.id]}$/i
        confirmation_codes.delete(message.chat.id)
        log = `echo '' > #{OWN_LOG}`
        bot.api.send_message(chat_id: message.chat.id, text: "#{OWN_LOG} cleared")
      # shutdown
      elsif message.text =~ /^shutdown\s#{password}$/i
        bot.api.send_message(chat_id: message.chat.id, text: "Send 'shutdown #{confirmation_codes[message.chat.id]}' to confirm")
      elsif confirmation_codes[message.chat.id] && message.text =~ /^shutdown\s#{confirmation_codes[message.chat.id]}/i
        bot.api.send_message(chat_id: message.chat.id, text: 'Shutting down')
        `shutdown -P now`
      # pull code
      elsif message.text =~ /^pull\scode\s#{password}$/i
        bot.api.send_message(chat_id: message.chat.id, text: "Send 'pull code #{confirmation_codes[message.chat.id]}' to confirm")
      elsif confirmation_codes[message.chat.id] && message.text =~ /^pull\scode\s#{confirmation_codes[message.chat.id]}/i
        confirmation_codes.delete(message.chat.id)
        output = `runuser -l #{user_name} -c "git fetch && git pull --ff-only"`
        bot.api.send_message(chat_id: message.chat.id, text: output)
      # subscribe
      elsif message.text =~ /^subscribe\s#{password}$/i
        bot.api.send_message(chat_id: message.chat.id, text: "Send 'subscribe #{confirmation_codes[message.chat.id]}' to confirm")
      elsif confirmation_codes[message.chat.id] && message.text =~ /^subscribe\s#{confirmation_codes[message.chat.id]}/i
        subs = subscribers
        if subs.include? message.chat.id
          bot.api.send_message(chat_id: message.chat.id, text: 'You are already subscribed')
        else
          subs << message.chat.id
          File.open(SUBSCRIBERS_FILE, 'w+') { |f| f.write({ 'subscribers' => subs }.to_json) }
          bot.api.send_message(chat_id: message.chat.id, text: 'You are now subscribed')
        end
      # unsubscribe
      elsif message.text =~ /^unsubscribe\s#{password}$/i
        bot.api.send_message(chat_id: message.chat.id, text: "Send 'unsubscribe #{confirmation_codes[message.chat.id]}' to confirm")
      elsif confirmation_codes[message.chat.id] && message.text =~ /^unsubscribe\s#{confirmation_codes[message.chat.id]}/i
        subs = subscribers
        if !subs.include?(message.chat.id)
          bot.api.send_message(chat_id: message.chat.id, text: 'You are not subscribed')
        else
          subs.reject! { |sub| sub == message.chat.id }
          File.open(SUBSCRIBERS_FILE, 'w+') { |f| f.write({ 'subscribers' => subs }.to_json) }
          bot.api.send_message(chat_id: message.chat.id, text: 'You are now unsubscribed')
        end
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Avaliable commands:\n#{AVAILABLE_COMMANDS.join(" %PASSWORD%\n")}")
      end
    rescue Exception => e
      p e
      p e.backtrace
    end
  end
end
