require 'spec_helper'

RSpec.describe 'Cottontail::Configurable' do
  let(:base_klass) do
    Class.new do
      include Cottontail::Configurable
    end
  end

  let(:config) { base_klass.config }

  it 'responds to :get' do
    expect(config).to respond_to(:get)
  end

  it 'responds to :set' do
    expect(config).to respond_to(:set)
  end

  context ':set with String' do
    let(:value) { 'value' }
    before { config.set(:key, value) }

    it 'returns the correct value' do
      expect(config.get(:key)).to eq(value)
    end
  end

  context ':set with Proc' do
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
