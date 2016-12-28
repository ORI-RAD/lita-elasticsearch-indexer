shared_examples 'an elasticsearch indexer' do |method_sym: :method, elasticsearch_url_sym: :elasticsearch_url|
  let(:elasticsearch_client) { 
    Elasticsearch::Client.new(host: send(elasticsearch_url_sym))
  }
  let(:existing_documents) { elasticsearch_client.search["hits"]["hits"] }
  let(:new_documents) { elasticsearch_client.search["hits"]["hits"] - existing_documents }
  before do
    expect{ existing_documents }.not_to raise_error
    expect{ send(method_sym) }.not_to raise_error
    expect{ elasticsearch_client.indices.flush }.not_to raise_error
    expect{ new_documents }.not_to raise_error
    expect(new_documents).not_to be_empty
  end
  after do
    new_documents.each do |d|
      elasticsearch_client.delete(
        id: d["_id"],
        index: d["_index"],
        type: d["_type"]
      )
    end
  end
end

shared_context 'with a single document indexed' do
  let(:document) { new_documents.first }
  before do
    expect(new_documents.length).to eq(1)
    expect(document).not_to be_nil
  end
end
