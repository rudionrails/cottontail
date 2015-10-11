require 'spec_helper'

RSpec.describe Cottontail::Consumer::Collection do
  let(:collection) { described_class.new }

  let(:entity_aaa) do
    Cottontail::Consumer::Entity.new(
      exchange: 'a',
      queue: 'a',
      route: 'a'
    )
  end

  let(:entity_bbb) do
    Cottontail::Consumer::Entity.new(
      exchange: 'b',
      queue: 'b',
      route: 'b'
    )
  end

  let(:entity_bab) do
    Cottontail::Consumer::Entity.new(
      exchange: 'b',
      queue: 'a',
      route: 'b'
    )
  end

  let(:entity_bba) do
    Cottontail::Consumer::Entity.new(
      exchange: 'b',
      queue: 'b',
      route: 'a'
    )
  end

  before do
    collection.push(entity_aaa)
    collection.push(entity_bbb)
    collection.push(entity_bab)
    collection.push(entity_bba)
  end

  context 'find by :route' do
    let(:delivery_info) do
    end

    it 'matches correctly' do
    end
  end

  private

  def delivery_info_stub(exchange = '', queue = '', route = '')
    OpenStruct.new(
      exchange: '',
      queue: OpenStruct.new(name: ''),
      route: ''
    )
  end
end

