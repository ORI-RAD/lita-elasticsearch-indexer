require 'elasticsearch'
module Lita
  module Handlers
    class ElasticsearchIndexer < Handler
      config :elasticsearch_url
      config :elasticsearch_index_name
      config :elasticsearch_index_type
      config :elasticsearch_index_options

      route(/^(.+)/,
        :index_conversation,
        help: { "info" =>
          "Stores conversations in elasticsearch"
      })

      def elasticsearch_client
        @@elasticsearch_client ||= Elasticsearch::Client.new(
          host: config.elasticsearch_url
        )
      end


      def index_conversation(response)
        user = response.user
        message = response.message
        room = message.room_object
        index = elasticsearch_client.index(
          index: 'rad-chat',
          type: 'message',
          body: {
            user: {id: user.id, name: user.name},
            message: {
              room: {id: room.id, name: room.name},
              body: message.body
            }
          }
        )
        response.reply "indexed => #{index}"
      end

      Lita.register_handler(self)
    end
  end
end
