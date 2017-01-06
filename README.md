# lita-elasticsearch-indexer

A [Lita](https://www.lita.io/) handler plugin that indexes messages to
[Elasticsearch](https://www.elastic.co/).

## Installation

Add lita-elasticsearch-indexer to your Lita instance's Gemfile:

``` ruby
gem "lita-elasticsearch-indexer"
```

## Configuration

### Required
* `elasticsearch_url` (String) - Host url for the Elasticsearch instance
* `elasticsearch_index_name` (String) - The name of the Elasticsearch index

### Optional
* `elasticsearch_index_type` (String) - The
  Elasticsearch document type. (default: 'message')
* `elasticsearch_index_options` (Proc) - A ruby `Proc` or `lambda` used to set index parameters or override the index body.

## Usage

Once installed and the required config variables are set, nothing else needs to
be done server side. The lita bot will automatically index any message that it
sees, including private messages sent directly to the bot. The bot can only
index messages that it sees, so nothing will be indexed from rooms the bot
has not joined.

### Setting elasticsearch index options with a Proc

Any of the optional arguments for [Elasticsearch::API::Actions index](http://www.rubydoc.info/gems/elasticsearch-api/Elasticsearch/API/Actions#index-instance_method) can be set via `elasticsearch_index_options` by creating a Proc 
(or lambda) that returns a Hash. The hash will be merged with the required
parameters and passed directly to the elasticsearch client index method. 

```
config.handlers.elasticsearch_indexer.elasticsearch_index_options = lambda {|response|
  options = {}
  if response.message.extensions[:slack]
    options[:id] = response.room.id + '-' + response.message.extensions[:slack][:timestamp]
  end
  options
}
```
