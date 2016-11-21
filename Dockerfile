FROM ruby:2.3
MAINTAINER Darin London <darin.london@duke.edu>
RUN gem install -N bundler lita

#miscellaneous
RUN ["mkdir","-p","/var/www"]
WORKDIR /var/www/app
ADD Gemfile /var/www/app/Gemfile
ADD Gemfile.lock /var/www/app/Gemfile.lock
ADD lita-elasticsearch-indexer.gemspec /var/www/app/lita-elasticsearch-indexer.gemspec

RUN ["bundle", "install", "--jobs=4"]

# run the app by defualt
CMD ["lita"]
