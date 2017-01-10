require "spec_helper"
require "faker"

describe Lita::Handlers::ElasticsearchIndexer, lita_handler: true do
  describe 'config' do
    let(:config) { Hash[described_class.configuration_builder.children.collect {|x| [x.name, x]}] }
    # Elasticsearch::Transport Client setting hosts documentation:
    #   http://www.rubydoc.info/gems/elasticsearch-transport/file/README.md#Setting_Hosts
    it { expect(config).to have_key(:elasticsearch_url) }
    it { expect(config[:elasticsearch_url]).to be_required }
    it { expect(config[:elasticsearch_url].types).to contain_exactly(String) }

    # Elasticsearch::API::Actions#index documentation:
    #   http://www.rubydoc.info/gems/elasticsearch-api/Elasticsearch/API/Actions#index-instance_method
    it { expect(config).to have_key(:elasticsearch_index_name) }
    it { expect(config[:elasticsearch_index_name]).to be_required }
    it { expect(config[:elasticsearch_index_name].types).to contain_exactly(String) }

    it { expect(config).to have_key(:elasticsearch_index_type) }
    it { expect(config[:elasticsearch_index_type]).not_to be_required }
    it { expect(config[:elasticsearch_index_type].types).to contain_exactly(String) }

    it { expect(config).to have_key(:elasticsearch_index_options) }
    it { expect(config[:elasticsearch_index_options]).not_to be_required }
    it { expect(config[:elasticsearch_index_options].types).to contain_exactly(Proc) }
  end

  describe '#index_conversation' do
    it { is_expected.to respond_to(:index_conversation).with(1).argument }

    context 'with a non-empty message' do
      let(:message) { Faker::Hacker.say_something_smart }
      let(:room_id) { Faker::Internet.slug }
      let(:private_message) { false }

      it { is_expected.to route(message).to(:index_conversation) }

      context 'send_message' do
        let(:method) { send_message(message, from: room_id, privately: private_message) }
        let(:registry_config) { registry.config.handlers.elasticsearch_indexer }
        let(:index_name) { "test-#{Faker::Internet.slug}" }
        let(:index_type) { "test-#{Faker::Internet.slug}" }
        let(:index_body) { {
          "user" => {
            "id" => user.id,
            "name" => user.name
          },
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

        it 'does not send a reply' do
          expect{ method }.not_to raise_error
          expect(replies).to be_empty
        end

        it_behaves_like 'an elasticsearch indexer' do
          include_context 'with a single document indexed'

          it { expect(document["_index"]).to eq(index_name) }
          it { expect(document["_type"]).to eq(index_type) }
          it { expect(document["_source"]).to include(index_body) }
        end

        context 'when elasticsearch_index_options' do
          let(:id) { Faker::Internet.slug }
          before do
            expect {
              registry_config.elasticsearch_index_options = index_options
            }.not_to raise_error
          end
          context 'is a Proc' do
            let(:index_options) {
              Proc.new { |response|
                {id: id}
              }
            }
            it_behaves_like 'an elasticsearch indexer' do
              include_context 'with a single document indexed'

              it { expect(document["_id"]).to eq(id) }
            end
          end

          context 'is a lambda' do
            let(:index_options) {
              lambda { |response|
                {id: id}
              }
            }
            it_behaves_like 'an elasticsearch indexer' do
              include_context 'with a single document indexed'

              it { expect(document["_id"]).to eq(id) }
            end
          end
        end
      end
    end

    context 'with an empty message' do
      it { is_expected.not_to route('').to(:index_conversation) }
    end
  end
end
