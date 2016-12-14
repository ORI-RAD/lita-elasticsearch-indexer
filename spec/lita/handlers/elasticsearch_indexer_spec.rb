require "spec_helper"
require "faker"

describe Lita::Handlers::ElasticsearchIndexer, lita_handler: true do
  let(:config) { registry.config.handlers.elasticsearch_indexer }
  let(:message) { Faker::Hacker.say_something_smart }

  it { is_expected.to route(message).to(:index_conversation) }
  it { is_expected.not_to route('').to(:index_conversation) }

  describe 'config' do
    it { expect(config).to respond_to(:elasticsearch_url) }
  end

  describe '#index_conversation' do
    before do
      config.elasticsearch_url = ENV['LITA_ELASTICSEARCH_URL']
    end
    it { is_expected.to respond_to(:index_conversation).with(1).argument }
  end
end
