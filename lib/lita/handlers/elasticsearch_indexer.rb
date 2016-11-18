module Lita
  module Handlers
    class ElasticsearchIndexer < Handler
      # insert handler code here

      route(/^(.+)/,
        :index_conversation,
        help: { "info" =>
          "Stores conversations in elasticsearch"
      })

      def index_conversation(response)
        response.reply "RECIEVED #{response.message.body} from #{response.message.source.room_object.inspect}"
      end

      Lita.register_handler(self)
    end
  end
end
