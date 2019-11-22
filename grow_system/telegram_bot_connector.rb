require 'json'
require 'telegram/bot'

class TelegramBotConnector
  TELEGRAM_MESSAGE_LENGTH_LIMIT = 4096.freeze
  MESSAGE_LENGTH_LIMIT          = (TELEGRAM_MESSAGE_LENGTH_LIMIT / 2).freeze

  def initialize(token)
    raise 'nil telegram token' if token.nil?

    @subscribers      = []
    @subscribers_file = "#{__dir__}/../.telegram_subscribers.json"

    @client  = Telegram::Bot::Client.new(token)

    if File.exist?(@subscribers_file) && File.file?(@subscribers_file)
      @subscribers = JSON.parse(File.open(@subscribers_file, 'r') { |f| f.read })['subscribers']
    end

    send_report(kind: 'notification', text: 'Bot has started')
  end

  def send_report(report = { kind: 'test', text: 'Test message' })
    retries = 0

    text_to_messages(report[:text]).each do |message|
      msg = <<~EOS
      #{report[:kind].capitalize}:
      #{message}
      EOS

      begin
        @subscribers.each { |s| @client.api.send_message(chat_id: s, text: msg) }
        retries = 0
      rescue Exception => e
        if retries < 5
          sleep(retries += 1)
          retry
        else
          p e
        end
      end
    end
  end

  private

  def text_to_messages(text = '')
    text.chars.each_slice(MESSAGE_LENGTH_LIMIT).map(&:join)
  end
end
