require 'spec_helper'

RSpec.describe Cottontail::Consumer::Collection do
  let(:collection) { described_class.new }

  context 'find for single entity' do
    it 'returns correctly for :exchange, :queue, :route' do
      entity = push_entity('a', 'b', 'c')

      expect(collection.find(delivery_info_stub('a', 'b', 'c'))).to eq(entity)
      expect(collection.find(delivery_info_stub('a', 'b', 'x'))).to be_nil
      expect(collection.find(delivery_info_stub('a', 'x', 'x'))).to be_nil
      expect(collection.find(delivery_info_stub('x', 'x', 'x'))).to be_nil
    end

    it 'returns correctly for :exchange, :queue, nil' do
      entity = push_entity('a', 'b', nil)

      expect(collection.find(delivery_info_stub('a', 'b', 'c'))).to eq(entity)
      expect(collection.find(delivery_info_stub('a', 'b', 'x'))).to eq(entity)
      expect(collection.find(delivery_info_stub('a', 'x', 'x'))).to be_nil
      expect(collection.find(delivery_info_stub('x', 'x', 'x'))).to be_nil
    end

    it 'returns correctly for :exchange, nil, nil' do
      entity = push_entity('a', nil, nil)

      expect(collection.find(delivery_info_stub('a', 'b', 'c'))).to eq(entity)
      expect(collection.find(delivery_info_stub('a', 'b', 'x'))).to eq(entity)
      expect(collection.find(delivery_info_stub('a', 'x', 'x'))).to eq(entity)
      expect(collection.find(delivery_info_stub('x', 'x', 'x'))).to be_nil
    end

    it 'returns correctly for nil, nil, nil' do
      entity = push_entity(nil, nil, nil)

      expect(collection.find(delivery_info_stub('a', 'b', 'c'))).to eq(entity)
      expect(collection.find(delivery_info_stub('a', 'b', 'x'))).to eq(entity)
      expect(collection.find(delivery_info_stub('a', 'x', 'x'))).to eq(entity)
      expect(collection.find(delivery_info_stub('x', 'x', 'x'))).to eq(entity)
    end
  end

  context 'find for multiple entities (ordered)' do
    let!(:nnn) { push_entity(nil, nil, nil) }
    let!(:ann) { push_entity('a', nil, nil) }
    let!(:abn) { push_entity('a', 'b', nil) }
    let!(:abc) { push_entity('a', 'b', 'c') }

    it 'returns correctly for :exchange, :queue, :route' do
      expect(collection.find(delivery_info_stub('a', 'b', 'c'))).to eq(abc)
      expect(collection.find(delivery_info_stub('a', 'b', 'x'))).to eq(abn)
      expect(collection.find(delivery_info_stub('a', 'x', 'x'))).to eq(ann)
      expect(collection.find(delivery_info_stub('x', 'x', 'x'))).to eq(nnn)
    end
  end

  context 'find for multiple entities (reverse ordered)' do
    let!(:abc) { push_entity('a', 'b', 'c') }
    let!(:abn) { push_entity('a', 'b', nil) }
    let!(:ann) { push_entity('a', nil, nil) }
    let!(:nnn) { push_entity(nil, nil, nil) }

    it 'returns correctly for :exchange, :queue, :route' do
      expect(collection.find(delivery_info_stub('a', 'b', 'c'))).to eq(abc)
      expect(collection.find(delivery_info_stub('a', 'b', 'x'))).to eq(abn)
      expect(collection.find(delivery_info_stub('a', 'x', 'x'))).to eq(ann)
      expect(collection.find(delivery_info_stub('x', 'x', 'x'))).to eq(nnn)
    end
  end

  context 'find for multiple entities (mixed)' do
    let!(:ann) { push_entity('a', nil, nil) }
    let!(:nan) { push_entity(nil, 'a', nil) }
    let!(:nna) { push_entity(nil, nil, 'a') }

    it 'returns correctly for :exchange, :queue, :route' do
      expect(collection.find(delivery_info_stub('a', 'x', 'x'))).to eq(ann)
      expect(collection.find(delivery_info_stub('x', 'a', 'x'))).to eq(nan)
      expect(collection.find(delivery_info_stub('x', 'x', 'a'))).to eq(nna)
      expect(collection.find(delivery_info_stub('x', 'x', 'x'))).to be_nil
    end
  end

  context 'find for multiple entities with the same signature' do
    let!(:ann_1) { push_entity('a', nil, nil) }
    let!(:ann_2) { push_entity('a', nil, nil) }
    let!(:nan_1) { push_entity(nil, 'a', nil) }
    let!(:nan_2) { push_entity(nil, 'a', nil) }
    let!(:nna_1) { push_entity(nil, nil, 'a') }
    let!(:nna_2) { push_entity(nil, nil, 'a') }
    let!(:nnn_1) { push_entity(nil, nil, nil) }
    let!(:nnn_2) { push_entity(nil, nil, nil) }

    it 'returns the last added entity for :exchange, :queue, :route' do
      expect(collection.find(delivery_info_stub('a', 'x', 'x'))).to eq(ann_2)
      expect(collection.find(delivery_info_stub('x', 'a', 'x'))).to eq(nan_2)
      expect(collection.find(delivery_info_stub('x', 'x', 'a'))).to eq(nna_2)
      expect(collection.find(delivery_info_stub('x', 'x', 'x'))).to eq(nnn_2)
    end
  end

  private

  def push_entity(exchange = nil, queue = nil, route = nil)
    entity = Cottontail::Consumer::Entity.new(
      {
        exchange: exchange,
        queue: queue,
        route: route
      }.reject { |_, v| v.nil? }
    )

    collection.push(entity)
    entity
  end

  def delivery_info_stub(exchange = '', queue = '', route = '')
    JSON.parse(
      {
        exchange: exchange,
        consumer: {
          queue: { name: queue }
        },
        routing_key: route
      }.to_json,
      object_class: OpenStruct
    )
  end
end
