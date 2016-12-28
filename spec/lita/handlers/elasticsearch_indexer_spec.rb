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
      let(:room_id) { Faker::Internet.slug }
      let(:private_message) { false }
      let(:escaped_message) {
        message.gsub(/([#{escaped_characters}])/, '\\\\\1') 
      }

      it { is_expected.to route(message).to(:index_conversation) }

      context 'send_message' do
        let(:method) { send_message(message, from: room_id, privately: private_message) }
        let(:registry_config) { registry.config.handlers.elasticsearch_indexer }
        let(:index_name) { "test-#{Faker::Internet.slug}" }
        let(:index_type) { "test-#{Faker::Internet.slug}" }
        let(:index_body) { {
          "message" => {
            "private" => private_message,
            "body" => message
          }
        } }
        let(:elasticsearch_url) { ENV['LITA_ELASTICSEARCH_URL'] }
        before do
          registry_config.elasticsearch_url = elasticsearch_url
          registry_config.elasticsearch_index_name = index_name
          registry_config.elasticsearch_index_type = index_type

          expect(registry_config.elasticsearch_url).not_to be_nil
        end

        it_behaves_like 'an elasticsearch indexer' do
          include_context 'with a single document indexed'

          it { expect(document["_index"]).to eq(index_name) }
          it { expect(document["_type"]).to eq(index_type) }
          it { expect(document["_source"]).to include(index_body) }
        end
      end
    end

    context 'with an empty message' do
      it { is_expected.not_to route('').to(:index_conversation) }
    end
  end
end
