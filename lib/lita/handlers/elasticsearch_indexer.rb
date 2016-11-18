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
        response.reply("GOT #{response.message.body}")
      end

      Lita.register_handler(self)
    end
  end
end
