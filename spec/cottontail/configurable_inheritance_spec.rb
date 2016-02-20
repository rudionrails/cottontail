require 'spec_helper'

RSpec.describe 'Cottontail::Configurable inheritance' do
  let(:base_klass) do
    Class.new do
      include Cottontail::Configurable

      set :foo, 123
    end
  end

  let(:child_klass) do
    Class.new(base_klass)
  end

  let(:base_config) { base_klass.config }
  let(:child_config) { child_klass.config }

  it 'inherits configuration' do
    expect(base_config.get(:foo)).to eq(123)
    expect(child_config.get(:foo)).to eq(123)
  end

  it 'does not override configuration of superclass' do
    child_config.set(:foo, 456)

    expect(child_config.get(:foo)).to eq(456)
    expect(base_config.get(:foo)).to eq(123)
  end
end
