require "spec_helper"
require "faker"

describe Lita::Handlers::ElasticsearchIndexer, lita_handler: true do
  let(:message) { Faker::Hacker.say_something_smart }

  it { is_expected.to route(message).to(:index_conversation) }
  it { is_expected.not_to route('').to(:index_conversation) }

  describe 'config' do
    let(:config) { Hash[described_class.configuration_builder.children.collect {|x| [x.name, x]}] }
    # Elasticsearch::Transport Client setting hosts documentation:
    #   http://www.rubydoc.info/gems/elasticsearch-transport/file/README.md#Setting_Hosts
    it { expect(config).to have_key(:elasticsearch_url) }
    it { expect(config[:elasticsearch_url]).to be_required }

    # Elasticsearch::API::Actions#index documentation:
    #   http://www.rubydoc.info/gems/elasticsearch-api/Elasticsearch%2FAPI%2FActions%3Aindex
    it { expect(config).to have_key(:elasticsearch_index_name) }
    it { expect(config[:elasticsearch_index_name]).to be_required }
    it { expect(config).to have_key(:elasticsearch_index_type) }
    it { expect(config).to have_key(:elasticsearch_index_options) }
  end

  describe '#index_conversation' do
    let(:registry_config) { registry.config.handlers.elasticsearch_indexer }
    before do
      registry_config.elasticsearch_url = ENV['LITA_ELASTICSEARCH_URL']
    end
    it { is_expected.to respond_to(:index_conversation).with(1).argument }
  end
end
