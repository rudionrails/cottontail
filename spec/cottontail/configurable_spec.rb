require 'spec_helper'

RSpec.describe Cottontail::Configurable do
  class ConfigurationFactory #:nodoc:
    include Cottontail::Configurable
  end

  let(:config) { ConfigurationFactory.config }
  before { config.reset! }

  it 'responds to :get' do
    expect(config).to respond_to(:get)
  end

  it 'responds to :set' do
    expect(config).to respond_to(:set)
  end

  context 'String' do
    let(:value) { 'value' }
    before { config.set(:key, value) }

    it 'returns the correct value' do
      expect(config.get(:key)).to eq(value)
    end
  end

  context 'Proc' do
    let(:value) { -> { 'value' } }
    before { config.set(:key, value) }

    it 'returns the correct value' do
      expect(config.get(:key)).to eq(value.call)
    end

    it 'calls only once' do
      v = config.get(:key)
      expect(config.get(:key)).to equal(v)
    end
  end
end
