require 'spec_helper'

RSpec.shared_examples_for 'a matching property' do
  it 'returns correctly for String' do
    entity = described_class.new(subject => 'a')

    expect(entity.matches?(subject, 'a')).to eq(true)
    expect(entity.matches?(subject, 'x')).to eq(false)
    expect(entity.matches?(subject, nil)).to eq(false)
    expect(entity.matches?(subject, :any)).to eq(false)
  end

  it 'returns correctly for nil' do
    entity = described_class.new(subject => nil)

    expect(entity.matches?(subject, 'a')).to eq(true)
    expect(entity.matches?(subject, 'x')).to eq(true)
    expect(entity.matches?(subject, nil)).to eq(true)
    expect(entity.matches?(subject, :any)).to eq(true)
  end

  it 'returns correctly for blank' do
    entity = described_class.new(subject => '')

    expect(entity.matches?(subject, 'a')).to eq(false)
    expect(entity.matches?(subject, 'x')).to eq(false)
    expect(entity.matches?(subject, nil)).to eq(false)
    expect(entity.matches?(subject, :any)).to eq(false)
  end

  it 'returns correctly for :any' do
    entity = described_class.new(subject => :any)

    expect(entity.matches?(subject, 'a')).to eq(true)
    expect(entity.matches?(subject, 'x')).to eq(true)
    expect(entity.matches?(subject, nil)).to eq(true)
    expect(entity.matches?(subject, :any)).to eq(true)
  end
end

RSpec.describe Cottontail::Consumer::Entity do
  context 'comparison' do
    let(:entity) { described_class.new }

    it 'is equal' do
      other = described_class.new

      expect(entity < other).to eq(false)
      expect(entity == other).to eq(true)
      expect(entity > other).to eq(false)
    end

    it 'is greater (exchange)' do
      other = described_class.new(exchange: 'exchange')

      expect(entity < other).to eq(false)
      expect(entity == other).to eq(false)
      expect(entity > other).to eq(true)
    end

    it 'is greater (queue)' do
      other = described_class.new(queue: 'queue')

      expect(entity < other).to eq(false)
      expect(entity == other).to eq(false)
      expect(entity > other).to eq(true)
    end

    it 'is greater (route)' do
      other = described_class.new(route: 'route')

      expect(entity < other).to eq(false)
      expect(entity == other).to eq(false)
      expect(entity > other).to eq(true)
    end
  end

  context 'comparison (more complex)' do
    let(:aaa) { described_class.new(exchange: 'a', queue: 'a', route: 'a') }
    let(:bbb) { described_class.new(exchange: 'b', queue: 'b', route: 'b') }
    let(:bab) { described_class.new(exchange: 'b', queue: 'a', route: 'b') }
    let(:bba) { described_class.new(exchange: 'b', queue: 'b', route: 'a') }

    let(:entities) { [bbb, bba, bab, aaa] }
    let(:sorted_entities) { [aaa, bab, bba, bbb] }

    it 'sorts correctly' do
      expect(entities.sort).to eq(sorted_entities)
    end
  end

  context 'comparison with nil' do
    let(:nnn) { described_class.new(exchange: nil, queue: nil, route: nil) }
    let(:ann) { described_class.new(exchange: 'a', queue: nil, route: nil) }
    let(:aan) { described_class.new(exchange: 'a', queue: 'a', route: nil) }
    let(:aaa) { described_class.new(exchange: 'a', queue: 'a', route: 'a') }

    let(:entities) { [nnn, ann, aan, aaa] }
    let(:sorted_entities) { [aaa, aan, ann, nnn] }

    it 'sorts correctly' do
      expect(entities.sort).to eq(sorted_entities)
    end
  end

  context 'matching for :exchange' do
    subject { :exchange }
    it_behaves_like 'a matching property'
  end

  context 'matching for :queue' do
    subject { :queue }
    it_behaves_like 'a matching property'
  end

  context 'matching for :queue' do
    subject { :route }
    it_behaves_like 'a matching property'
  end
end
