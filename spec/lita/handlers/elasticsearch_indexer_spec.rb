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
      let(:escaped_characters) { Regexp.escape('\\+-&|!(){}[]^~*?:\/') }
      let(:message) { Faker::Hacker.say_something_smart }
      let(:escaped_message) {
        message.gsub(/([#{escaped_characters}])/, '\\\\\1') 
      }

      it { is_expected.to route(message).to(:index_conversation) }

      context 'send_message' do
        let(:registry_config) { registry.config.handlers.elasticsearch_indexer }
        let(:index_name) { "test-#{Faker::Internet.slug}" }
        let(:index_type) { "test-#{Faker::Internet.slug}" }
        let(:elasticsearch_url) { ENV['LITA_ELASTICSEARCH_URL'] }
        let(:elasticsearch_client) { 
          Elasticsearch::Client.new(host: elasticsearch_url)
        }
        let(:search) { elasticsearch_client.search(body: { query: { query_string: {query: escaped_message, default_operator: "AND"}}}) }
        let(:document) { search && search["hits"]["hits"].first }
        before do
          registry_config.elasticsearch_url = elasticsearch_url
          registry_config.elasticsearch_index_name = index_name
          registry_config.elasticsearch_index_type = index_type

          expect(registry_config.elasticsearch_url).not_to be_nil
          expect{ send_message(message) }.not_to raise_error
          expect{ elasticsearch_client.indices.flush }.not_to raise_error
          expect{ search }.not_to raise_error
          expect(search["hits"]["total"]).to eq(1)
          expect(document).not_to be_nil
        end
        after do
          elasticsearch_client.delete(
            id: document["_id"],
            index: document["_index"],
            type: document["_type"]
          ) if document
        end

        it { expect(document["_index"]).to eq(index_name) }
        it { expect(document["_type"]).to eq(index_type) }
      end
    end

    context 'with an empty message' do
      it { is_expected.not_to route('').to(:index_conversation) }
    end
  end
end
