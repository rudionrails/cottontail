require 'spec_helper'

RSpec.describe Cottontail::Consumer::Entity do
  context 'comparison' do
    let(:entity) do
      described_class.new
    end

    it 'is equal' do
      other = described_class.new

      expect(entity).to_not be < other
      expect(entity).to be == other
      expect(entity).to_not be > other
    end

    it 'is greater (exchange)' do
      other = described_class.new(exchange: 'exchange')

      expect(entity).to be < other
      expect(entity).to_not be == other
      expect(entity).to_not be > other
    end

    it 'is greater (queue)' do
      other = described_class.new(queue: 'queue')

      expect(entity).to be < other
      expect(entity).to_not be == other
      expect(entity).to_not be > other
    end

    it 'is greater (route)' do
      other = described_class.new(route: 'route')

      expect(entity).to be < other
      expect(entity).to_not be == other
      expect(entity).to_not be > other
    end
  end

  context 'comparison (more complex)' do
    let(:entity_aaa) do
      described_class.new(exchange: 'a', queue: 'a', route: 'a')
    end

    let(:entity_bbb) do
      described_class.new(exchange: 'b', queue: 'b', route: 'b')
    end

    let(:entity_bab) do
      described_class.new(exchange: 'b', queue: 'a', route: 'b')
    end

    let(:entity_bba) do
      described_class.new(exchange: 'b', queue: 'b', route: 'a')
    end

    let(:entities) { [entity_bbb, entity_bba, entity_bab, entity_aaa] }
    let(:sorted_entities) { [entity_aaa, entity_bab, entity_bba, entity_bbb] }

    it 'sorts correctly' do
      expect(entities.sort).to eq(sorted_entities)
    end
  end
end
