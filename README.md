[![Build Status](https://travis-ci.org/jbgo/chasqui.svg?branch=master)](https://travis-ci.org/jbgo/chasqui)
[![Code Climate](https://codeclimate.com/github/jbgo/chasqui/badges/gpa.svg)](https://codeclimate.com/github/jbgo/chasqui)

# Chasqui

Chasqui is a simple, lightweight, persistent implementation of the publish-subscribe (pub-sub)
messaging pattern for service oriented architectures.

Chasqui delivers messages to subscribers in a Resque-compatible format. If you are already
using Resque and/or Sidekiq, Chasqui will make a wonderful companion to your architecture.

## Installation

Add this line to your application's Gemfile:

    gem 'chasqui'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chasqui

## Dependencies

Chasqui uses Redis to queue events and manage subscriptions. You can install
Redis with your favorite package manager, such as homebrew, yum, or apt, or if
you prefer, you can run `vagrant up` to run Redis in a virtual machine.

## Quick Start

Chasqui consistents of two components - a client and a broker. The broker's
responsibility is to forward published events to registered subscribers. The
client can both publish events and register subscribers.

### Start the broker

    chasqui -r redis://localhost:6379/0 -q my-app

Your broker must use the same Redis connection as your Sidekiq (or Resque)
workers. For a list of available broker options, see `chasqui --help`.

### Publish events

Publishing events is simple.

    # file: publisher.rb
    require 'chasqui'
    Chasqui.publish 'user.sign-up', 'Darth Vader'
    Chasqui.publish 'user.cancel', 'Luke Skywalker', 'May the force be with you.'

Be sure to run the publisher, broker, and subscribers in separate terminal
windows.

    ruby publisher.rb

### Subscribe to events

Subscribing to events is also simple. The following example tells Chasqui to
forward events to this subscriber's `my-app` queue. Chasqui will detect whether
you are using Sidekiq or Resque and generate an appropriate worker class for you.
Within the subscriber block, you use the `on(event_name)` method to register blocks
of code to handle that event.

    # file: subscriber1.rb
    require 'chasqui'

    Chasqui.subscribe queue: 'my-app' do

      on 'user.sign-up' do |user_id|
        # do something when the user signs up
      end

      on 'user.cancel' do |user_id, reason|
        # do something else when user cancels
      end

    end

You can have as many subscribers as you like, but __each subscriber must have
its own unique queue name__.

### Running Sidekiq subscribers

Here is how you can run the subscriber as a sidekiq worker:

    sidekiq -r subscriber.rb

For more information on running Sidekiq, please refer to the [Sidekiq documentation](https://github.com/mperham/sidekiq).

### Running Resque subscribers

To run the resque worker, you first need to create a Rakefile.

    # Rakefile
    require 'resque'
    require 'resque/tasks'

    task 'resque:setup' => ['chasqui:subscriber']

    namespace :chasqui do
      task :subscriber do
        require './subscriber.rb'
      end
    end

Then you can run the resque worker to start processing events.

    rake resque:work

For more information on running Resque workers, please refer to the [resque documentation](https://github.com/resque/resque).

## Why Chasqui?

* Reduces coupling between applications.
* Simple to learn and use.
* Integrates with the popular Sidekiq and Resque background worker libraries.
* Queues events for registered subscribers even if a subscriber is unavailable.
* Subscribers can benefit from Sidekiq's built-in retry functionality for failed jobs.

## Limitations

In order for Chasqui to work properly, the publisher, broker, and all
subscribers must connect to the same Redis database. Chasqui is intentionally
simple and may not have all of the features you would expect from a messaging
system. If Chasqui is missing a feature that you think it should have, please
consider [opening a GitHub issue](https://github.com/jbgo/chasqui/issues/new) to
discuss your feature proposal. 

## Contributing

* For new functionality, please open an issue for discussion before creating a pull request.
* For bug fixes, you are welcome to create a pull request without first opening an issue.
* Except for documentation changes, tests are required with all pull requests.
* Please be polite and respectful when discussing the project with maintainers and your fellow contributors.

## Code of Conduct

If you are unsure whether or not your communication may be inappropriate, please consult the [Chasqui Code of Conduct](code-of-conduct.md).
If you even suspect harassment or abuse, please report it to the email address listed in the Code of Conduct.
