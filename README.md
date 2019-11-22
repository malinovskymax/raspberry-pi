[![Build Status](https://travis-ci.org/malinovskymax/raspberry-pi.svg?branch=master)](https://travis-ci.org/malinovskymax/raspberry-pi)

### Usage
On your RPI open `/etc/profile` in text editor. To the end of the file add:
```
TELEGRAM_BOT_API_TOKEN="%TOKEN%"
SUBSCRIBER_PASSWORD="%PASSWORD%"

sudo env TELEGRAM_BOT_API_TOKEN=$TELEGRAM_BOT_API_TOKEN SUBSCRIBER_PASSWORD=$SUBSCRIBER_PASSWORD /home/pi/.rvm/rubies/ruby-2.6.5/bin/ruby -C /home/pi/raspberry-pi/grow_system /home/pi/raspberry-pi/grow_system/grow-system.rb > /home/pi/grow_log 2>&1 &

TELEGRAM_BOT_PASSWORD="%TELEGRAM_BOT_PASSWORD%"
sudo env TELEGRAM_BOT_API_TOKEN=$TELEGRAM_BOT_API_TOKEN /home/pi/.rvm/rubies/ruby-2.6.5/bin/ruby -C /home/pi/raspberry-pi/remote_control_bot /home/pi/raspberry-pi/remote_control_bot/remote_control_bot.rb > /home/pi/raspberry-pi/remote_control_bot/log 2>&1 &
```
Reboot your RPI.
