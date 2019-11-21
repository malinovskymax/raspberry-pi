require 'time'

require_relative '../light_control'

RSpec.describe 'LightControl' do
  let(:gpio) { double('GPIO interface') }
  let(:instance) { LightControl.new(gpio, {}) }

  before do
    allow(gpio).to receive(:set_numbering)
    allow(gpio).to receive(:setup)
  end

  describe 'default params' do
    it '@light_is_on defaults to false' do
      expect(instance.instance_variable_get('@light_is_on')).to eq(false)
    end

    it '@light_pin defaults to 8' do
      expect(instance.instance_variable_get('@light_pin')).to eq(8)
    end

    it '@relay_on_level defaults to :low' do
      expect(instance.instance_variable_get('@relay_on_level')).to eq(:low)
    end

    it '@external_light_sensor defaults to false' do
      expect(instance.instance_variable_get('@external_light_sensor')).to eq(false)
    end

    it '@external_light_sensor_pin defaults to 10' do
      expect(instance.instance_variable_get('@external_light_sensor_pin')).to eq(10)
    end

    it '@diagnose defaults to false' do
      expect(instance.instance_variable_get('@diagnose')).to eq(false)
    end

    it '@diagnose_options is not set by default' do
      expect(instance.instance_variable_get('@diagnose_options')).to eq(nil)
    end

    it '@autumn_months is an equivavlen of [9, 10, 11]' do
      expect(instance.instance_variable_get('@autumn_months').to_a.sort).to eq([9, 10, 11])
    end

    it '@winter_months is an equivavlen of [1, 2, 12]' do
      expect(instance.instance_variable_get('@winter_months').to_a.sort).to eq([1, 2, 12])
    end

    it '@spring_months is an equivavlen of [3, 4, 5]' do
      expect(instance.instance_variable_get('@spring_months').to_a.sort).to eq([3, 4, 5])
    end

    it '@summer_autumn_months is an equivavlen of [6, 7, 8]' do
      expect(instance.instance_variable_get('@summer_months').to_a.sort).to eq([6, 7, 8])
    end

    it '@autumn_light_hours is an equivavlen of 6..20' do
      expect(instance.instance_variable_get('@autumn_light_hours').to_a).to eq((6..20).to_a)
    end
  
    it '@winter_light_hours is an equivavlen of 6..20' do
      expect(instance.instance_variable_get('@winter_light_hours').to_a).to eq((6..20).to_a)
    end
  
    it '@spring_light_hours is an equivavlen of 6..20' do
      expect(instance.instance_variable_get('@spring_light_hours').to_a).to eq((6..20).to_a)
    end
  
    it '@summer_light_hours is an equivavlen of 6..20' do
      expect(instance.instance_variable_get('@summer_light_hours').to_a).to eq((6..20).to_a)
    end
  end

  describe 'initialization' do
    it 'accepts GPIO interface and configuration hash' do
      light_controller = LightControl.new(gpio, light_pin: 1,
                                                relay_on_level: :high,
                                                external_light_sensor: true,
                                                external_light_sensor_pin: 12,
                                                autumn_months: 1..2,
                                                winter_months: 3..4,
                                                spring_months: 5..6,
                                                summer_months: 7..8,
                                                autumn_light_hours: 9..10,
                                                winter_light_hours: 11..12,
                                                spring_light_hours: 13..14,
                                                summer_light_hours: 15..16,
                                                diagnose: {
                                                  enabled: true,
                                                  abnormal_phase_duration: 17
                                                })

      expect(light_controller.instance_variable_get('@gpio')).to eql(gpio)

      expect(light_controller.instance_variable_get('@light_pin')).to eq(1)

      expect(light_controller.instance_variable_get('@external_light_sensor')).to eq(true)
      expect(light_controller.instance_variable_get('@external_light_sensor_pin')).to eq(12)

      expect(light_controller.instance_variable_get('@diagnose')).to eq(true)
      expect(light_controller.instance_variable_get('@diagnose_options')[:abnormal_phase_duration]).to eq(17)

      expect(light_controller.instance_variable_get('@autumn_months')).to eq(1..2)
      expect(light_controller.instance_variable_get('@winter_months')).to eq(3..4)
      expect(light_controller.instance_variable_get('@spring_months')).to eq(5..6)
      expect(light_controller.instance_variable_get('@summer_months')).to eq(7..8)

      expect(light_controller.instance_variable_get('@autumn_light_hours')).to eq(9..10)
      expect(light_controller.instance_variable_get('@winter_light_hours')).to eq(11..12)
      expect(light_controller.instance_variable_get('@spring_light_hours')).to eq(13..14)
      expect(light_controller.instance_variable_get('@summer_light_hours')).to eq(15..16)
    end
  end

  describe '#tick' do
    it 'turns light on or off according to current time' do
      allow(instance).to receive(:light_needed?).and_return(true)
      expect(instance).to receive(:light_on)
      instance.tick

      allow(instance).to receive(:light_needed?).and_return(false)
      expect(instance).to receive(:light_off)
      instance.tick
    end
  end

  describe '#light_on' do
    it 'immidiately returns if @light_is_on' do
      instance.instance_variable_set('@light_is_on', true)
      expect { instance.send(:light_on) }.to_not change { instance.instance_variable_get('@light_is_on') }
    end

    it 'calls GPIO interface and changes light state' do
      expect(instance).to receive(:send_gpio_light_on)
      expect { instance.send(:light_on) }.to change { instance.instance_variable_get('@light_is_on') }.from(false).to(true)
    end
  end

  describe '#light_off' do
    it 'immidiately returns if !@light_is_on' do
      instance.instance_variable_set('@light_is_on', false)
      expect { instance.send(:light_off) }.to_not change { instance.instance_variable_get('@light_is_on') }
    end

    it 'calls GPIO interface and changes light state' do
      instance.instance_variable_set('@light_is_on', true)
      expect(instance).to receive(:send_gpio_light_off)
      expect { instance.send(:light_off) }.to change { instance.instance_variable_get('@light_is_on') }.from(true).to(false)
    end
  end

  describe '#season' do
    it 'returns season code for given month number' do
      expect(instance.send(:season, 1)).to eq(:winter)
      expect(instance.send(:season, 2)).to eq(:winter)

      expect(instance.send(:season, 3)).to eq(:spring)
      expect(instance.send(:season, 4)).to eq(:spring)
      expect(instance.send(:season, 5)).to eq(:spring)

      expect(instance.send(:season, 6)).to eq(:summer)
      expect(instance.send(:season, 7)).to eq(:summer)
      expect(instance.send(:season, 8)).to eq(:summer)

      expect(instance.send(:season, 9)).to eq(:autumn)
      expect(instance.send(:season, 10)).to eq(:autumn)
      expect(instance.send(:season, 11)).to eq(:autumn)

      expect(instance.send(:season, 12)).to eq(:winter)
    end

    it 'raises an error if given month number does not belong to any season' do
      expect { instance.send(:season, 0) }.to raise_error('month number: 0 does not belong to any season defined in the options')
    end
  end

  describe '#light_hours' do
    it 'returns a set of numbers of hours when light must be turned on during given season' do
      expect(instance.send(:light_hours, :autumn).to_a).to eq((6..20).to_a)
      expect(instance.send(:light_hours, :winter).to_a).to eq((6..20).to_a)
      expect(instance.send(:light_hours, :spring).to_a).to eq((6..20).to_a)
      expect(instance.send(:light_hours, :summer).to_a).to eq((6..20).to_a)
    end
  end

  describe '#enough_external_light?' do
    let(:external_light_sensor_pin) { instance.instance_variable_get('@external_light_sensor_pin') }

    it 'returns true if external light sensor detects enough light' do
      expect(gpio).to receive(:low?).with(external_light_sensor_pin).and_return(true)

      expect(instance.send(:enough_external_light?)).to eq(true)
    end

    it 'returns false if external light sensor does not detect enough light' do
      expect(gpio).to receive(:low?).with(external_light_sensor_pin).and_return(false)

      expect(instance.send(:enough_external_light?)).to eq(false)
    end
  end

  describe '#diagnose' do
    before { instance.instance_variable_set('@diagnose_options', { abnormal_phase_duration: 17 }) }

    context 'on first call' do
      it 'sets instanse variables needed for diagnosis' do
        expect(instance.instance_variable_get('@diagnose_start_time')).to eq(nil)
        expect(instance.instance_variable_get('@light_mode_stuck_for_long_time')).to eq(nil)
        expect(instance.instance_variable_get('@how_many_hours_current_light_mode_lasts')).to eq(nil)
  
        instance.send(:diagnose, false)
  
        expect(instance.instance_variable_get('@diagnose_start_time')).to be_an_instance_of(Time)
        expect(instance.instance_variable_get('@light_mode_stuck_for_long_time')).to eq(false)
        expect(instance.instance_variable_get('@how_many_hours_current_light_mode_lasts')).to eq(0)
      end

      it 'never calls #send_gpio_light_blink' do
        expect(instance).to_not receive(:send_gpio_light_blink)
        instance.send(:diagnose, false)
      end
    end

    context 'on subsequent calls' do
      before { instance.send(:diagnose, false) }

      it 'detects if light mode has not been swithed for a long time' do
        current_light_mode = instance.instance_variable_get('@light_is_on')
        instance.instance_variable_set('@diagnose_options', { abnormal_phase_duration: 17 })
        instance.instance_variable_set('@diagnose_start_time', (DateTime.now - (17 / 24.0)).to_time)
        allow(instance).to receive(:send_gpio_light_blink)
        instance.send(:diagnose, current_light_mode)
        expect(instance.instance_variable_get('@light_mode_stuck_for_long_time')).to eq(true)
      end

      it 'does not detect problem if light mode changing on the edge of allowed normal period' do
        current_light_mode = instance.instance_variable_get('@light_is_on')
        instance.instance_variable_set('@diagnose_options', { abnormal_phase_duration: 17 })
        instance.instance_variable_set('@diagnose_start_time', (DateTime.now - (17 / 24.0)).to_time)
        allow(instance).to receive(:send_gpio_light_blink)
        instance.send(:diagnose, !current_light_mode)
        expect(instance.instance_variable_get('@light_mode_stuck_for_long_time')).to eq(false)
      end

      it 'detects if light mode has not been swithed for a long time with no more than 1s precision' do
        current_light_mode = instance.instance_variable_get('@light_is_on')
        instance.instance_variable_set('@diagnose_options', { abnormal_phase_duration: 17 })
        instance.instance_variable_set('@diagnose_start_time', (DateTime.now - (16 / 24.0) - (59 / 1440.0) - (59 / 86400.0)).to_time)
        allow(instance).to receive(:send_gpio_light_blink)
        instance.send(:diagnose, !current_light_mode)
        expect(instance.instance_variable_get('@light_mode_stuck_for_long_time')).to eq(false)
      end

      it 'blinks light if problem detected' do
        instance.instance_variable_set('@light_mode_stuck_for_long_time', true)
        expect(instance).to receive(:send_gpio_light_blink)
        instance.send(:diagnose, false)
      end
    end
  end

  describe '#light_needed?' do
    it 'call #diagnose if diagnose mode is disabled' do
      instance.instance_variable_set('@diagnose', false)
      expect(instance).to_not receive(:diagnose)
      instance.send(:light_needed?, Time.now)
    end

    it 'call #diagnose if diagnose mode is enabled' do
      instance.instance_variable_set('@diagnose', true)
      expect(instance).to receive(:diagnose)
      instance.send(:light_needed?, Time.now)
    end

    context 'without external light sensor' do
      before { instance.instance_variable_set('@external_light_sensor', false) }

      it 'does not try to get external light level from sensor' do
        expect(gpio).to_not receive(:low?)

        instance.send(:light_needed?, Time.now)
      end

      it 'returns true if light must be turned on at a given time, otherwise returns false' do
        expect(instance.send(:light_needed?, Time.parse('2019-9-7 6:57:33'))).to eq(true)
        expect(instance.send(:light_needed?, Time.parse('2019-9-7 5:57:33'))).to eq(false)
        expect(instance.send(:light_needed?, Time.parse('2019-9-7 21:57:33'))).to eq(false)
  
        expect(instance.send(:light_needed?, Time.parse('2019-1-7 9:57:33'))).to eq(true)
        expect(instance.send(:light_needed?, Time.parse('2019-1-7 4:57:33'))).to eq(false)
        expect(instance.send(:light_needed?, Time.parse('2019-1-7 22:57:33'))).to eq(false)
  
        expect(instance.send(:light_needed?, Time.parse('2019-3-7 12:57:33'))).to eq(true)
        expect(instance.send(:light_needed?, Time.parse('2019-3-7 3:57:33'))).to eq(false)
        expect(instance.send(:light_needed?, Time.parse('2019-3-7 23:57:33'))).to eq(false)
  
        expect(instance.send(:light_needed?, Time.parse('2019-6-7 20:57:33'))).to eq(true)
        expect(instance.send(:light_needed?, Time.parse('2019-6-7 2:57:33'))).to eq(false)
        expect(instance.send(:light_needed?, Time.parse('2019-6-7 0:57:33'))).to eq(false)
      end
    end

    context 'with exteral light sensor' do
      before { instance.instance_variable_set('@external_light_sensor', true) }

      let(:external_light_sensor_pin) { instance.instance_variable_get('@external_light_sensor_pin') }

      it 'trys to get external light level from sensor' do
        expect(gpio).to receive(:low?).with(external_light_sensor_pin)

        instance.send(:light_needed?, Time.now)
      end

      it 'takes into account if external light sensor detects enough light' do
        expect(gpio).to receive(:low?).with(external_light_sensor_pin).and_return(true).twice
        expect(instance.send(:light_needed?, Time.parse('2019-11-19 7:30:0'))).to eq(false)
        expect(instance.send(:light_needed?, Time.parse('2019-6-7 0:30:0'))).to eq(false)

        expect(gpio).to receive(:low?).with(external_light_sensor_pin).and_return(false).twice
        expect(instance.send(:light_needed?, Time.parse('2019-11-19 7:30:0'))).to eq(true)
        expect(instance.send(:light_needed?, Time.parse('2019-6-7 0:30:0'))).to eq(false)
      end
    end
  end

  describe '#send_gpio_light_on' do
    it 'calls GPIO interface' do
      expect(gpio).to receive(:set_low)
      instance.send(:send_gpio_light_on)
    end
  end

  describe '#send_gpio_light_off' do
    it 'calls GPIO interface' do
      expect(gpio).to receive(:set_high)
      instance.send(:send_gpio_light_off)
    end
  end

  describe '#send_gpio_light_blink' do
    it 'turns light down, up, and down again' do
      expect(instance).to receive(:sleep).with(0.5).twice
      expect(instance).to receive(:send_gpio_light_off).twice
      expect(instance).to receive(:send_gpio_light_on).once
      instance.send(:send_gpio_light_blink)
    end
  end
end
