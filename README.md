[![Build Status](https://travis-ci.org/malinovskymax/raspberry-pi.svg?branch=master)](https://travis-ci.org/malinovskymax/raspberry-pi)

## Usage
### Grow system and reporting
On your RPI open `/etc/profile` in text editor. To the end of the file add:
```
# Grow system. Requires TELEGRAM_BOT_API_TOKEN for reporting.
TELEGRAM_BOT_API_TOKEN="%TOKEN%"
sudo env TELEGRAM_BOT_API_TOKEN=$TELEGRAM_BOT_API_TOKEN /home/pi/.rvm/rubies/ruby-2.6.5/bin/ruby -C /home/pi/raspberry-pi/grow_system /home/pi/raspberry-pi/grow_system/grow-system.rb > /home/pi/grow_log 2>&1 &

# Remote control bot. Pay attention that it requires both TELEGRAM_BOT_API_TOKEN and TELEGRAM_BOT_PASSWORD
TELEGRAM_BOT_PASSWORD="%TELEGRAM_BOT_PASSWORD%"
sudo env TELEGRAM_BOT_API_TOKEN=$TELEGRAM_BOT_API_TOKEN TELEGRAM_BOT_API_TOKEN=$TELEGRAM_BOT_API_TOKEN /home/pi/.rvm/rubies/ruby-2.6.5/bin/ruby -C /home/pi/raspberry-pi/remote_control_bot /home/pi/raspberry-pi/remote_control_bot/remote_control_bot.rb > /home/pi/bot_log 2>&1 &
```
Reboot your RPI.

### Remote control bot
Sent any message to the bot to see the list of available commands.
