require "spec_helper"
require "faker"

describe Lita::Handlers::ElasticsearchIndexer, lita_handler: true do
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
    it { is_expected.to respond_to(:index_conversation).with(1).argument }

    context 'with a non-empty message' do
      let(:message) { Faker::Hacker.say_something_smart }

      it { is_expected.to route(message).to(:index_conversation) }

      context 'send_message' do
        let(:registry_config) { registry.config.handlers.elasticsearch_indexer }
        let(:index_name) { 'lita-handler-test' }
        before do
          registry_config.elasticsearch_url = ENV['LITA_ELASTICSEARCH_URL']
          registry_config.elasticsearch_index_name = index_name

          expect(registry_config.elasticsearch_url).not_to be_nil
        end

        it { expect{ send_message(message) }.not_to raise_error }
      end
    end

    context 'with an empty message' do
      it { is_expected.not_to route('').to(:index_conversation) }
    end
  end
end
