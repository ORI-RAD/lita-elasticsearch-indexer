Gem::Specification.new do |spec|
  spec.name          = "lita-elasticsearch-indexer"
  spec.version       = "0.1.0"
  spec.authors       = ["Darrin Mann", "Darin London"]
  spec.email         = ["darrin.mann@duke.edu", "darin.london@duke.edu"]
  spec.description   = <<-EOF
    lita-elasticsearch-indexer is a lurker-bot that silently indexes all messages posted
    by all users in any room to which it has been invited. It can also index
    private messages sent directly to the bot. The bot will not index any messages
    posted to rooms to which it has not been invited.
  EOF
  spec.summary       = "Listens to channel conversations and stores them to elasticsearch"
  spec.homepage      = "https://github.com/ORI-RAD/lita-elasticsearch-indexer"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.7"
  spec.add_runtime_dependency "elasticsearch"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "faker"
end
