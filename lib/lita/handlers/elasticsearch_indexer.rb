require 'pry'
require 'elasticsearch'
module Lita
  module Handlers
    class ElasticsearchIndexer < Handler
      config :elasticsearch_url, type: String, required: true
      config :elasticsearch_index_name, type: String, required: true
      config :elasticsearch_index_type, type: String, default: "message"
      config :elasticsearch_index_options, type: Proc

      route(/^(.+)/,
        :index_conversation,
        help: { "info" =>
          "Stores conversations in elasticsearch"
      })

      def elasticsearch_client
        @@elasticsearch_client ||= Elasticsearch::Client.new(
          urls: config.elasticsearch_url
        )
      end

      def index_conversation(response)
        user = response.user
        message = response.message
        room = message.room_object
        index_body = {
          user: {id: user.id, name: user.name},
          message: {
            private: message.private_message?,
            body: message.body
          }
        }
        index_body[:room] = {id: room.id, name: room.name} if room
        index_params = {
          body: index_body
        }.merge(elasticsearch_index_options(response))
        index_params[:index] = config.elasticsearch_index_name
        index_params[:type] = config.elasticsearch_index_type
        index = elasticsearch_client.index(index_params)
        response.reply "indexed => #{index}"
      end

      Lita.register_handler(self)

      private

      def elasticsearch_index_options(response)
        if config.elasticsearch_index_options
          config.elasticsearch_index_options.call(response)
        else
          {}
        end
      end
    end
  end
end
