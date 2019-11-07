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
                                                autumn_months: 1..2,
                                                winter_months: 3..4,
                                                spring_months: 5..6,
                                                summer_months: 7..8,
                                                autumn_light_hours: 9..10,
                                                winter_light_hours: 11..12,
                                                spring_light_hours: 13..14,
                                                summer_light_hours: 15..16)

      expect(light_controller.instance_variable_get('@gpio')).to eql(gpio)

      expect(light_controller.instance_variable_get('@light_pin')).to eq(1)

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
      expect(gpio).to receive(:set_low)
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
      expect(gpio).to receive(:set_high)
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
      expect { instance.send(:season, 0) }.to raise_error('month number: 0 does not belong to any season defined in the settings.rb')
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

  describe '#light_needed?' do
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
end
