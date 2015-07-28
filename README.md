# GrapeTokenAuth

> __This gem is in active development__ and is not ready for production. See this
issue milestone for reaching [functional parity with devise token auth][10] and
being ready. Feel free to ping me if you want to help.

GrapeTokenAuth is a token authentication solution for grape. It is compatible
with [ng-token-auth][1] (for angular) and [j-toker][2] (for jquery) and is meant
as a [grape][4] (rather than rails) version of [devise_token_auth][3]. As such,
one of the primary goals of this project is to only depend on grape and
[warden][9] and thus not make presumptions that you are using rails. If
you are placing a grape app within a rails+devise app you might be
interested in [grape_devise_token_auth][5].

This gem is a port of [devise_token-auth][4] written by [Lyann Dylan
Hurley][6] who did great work and I highly recommend reading his [conceptual
section on that gem][7].

_Philosophy_

This gem aims to maintain a small direct dependency footprint. As such,
it currently depends only on grape, warden, and bcrypt.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grape_token_auth'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grape_token_auth

## Setup

###Middleware setup

GrapeTokenAuth requires setting up warden middleware in order to function
properly. In a simple rack environment this is usually as easy as adding the
following to the `config.ru`:

```ruby
require 'warden'

use Warden::Manager do |manager|
  manager.failure_app = GrapeTokenAuth::UnauthorizedMiddleware
end

run YourGrapeAPI
```

In rails it might look like this:

`application.rb`:

```ruby
config.middleware.insert_after ActionDispatch::Flash, Warden::Manager do |manager|
  manager.failure_app = GrapeTokenAuth::UnauthorizedMiddleware
end
```

###Model/ORM setup

Include the module for your ORM within the model classes. At the moment, only
ActiveRecord is supported but other ORMs are planned. Your model must
contain a text-type field called `tokens`.

####ActiveRecord

```ruby
class User < ActiveRecord::Base
  include GrapeTokenAuth::ActiveRecord::TokenAuth
end
```

###Define mappings

GTA does not make guesses about what scopes and user classes you are using, you
must define them before the Grape API is loaded. In rails this could be in a
initializer, in a simple rack app it could be in `config.ru`).

To define mappings the scope is the key of the mapping hash and the value is the
Model that the scope maps to. For the above user class this would be:

```ruby
GrapeTokenAuth.setup! do |config|
	config.mappings = { user: User }
end
```

##Grape::API integrations

Finally, include `GrapeTokenAuth::TokenAuthentication` within the Grape::API you
want to protect. For example:

```ruby
class TestApp < Grape::API
  format :json

  include GrapeTokenAuth::TokenAuthentication

  #...
end
```

##Usage

In any Grape endpoint you can call `authenticate_{SCOPE}!` to enforce
authentication on that endpoint. For example, the following:

```ruby
get '/' do
  authenticate_user!
  present Post.all
end
```

would authenticate against the `:user` scope when trying to GET the `/` route.

Alternatively, if you want to protect all of the endpoints in a API file, place
the authentication call in a before filter, like so:

```ruby
class TestApp < Grape::API
  before do
    :authenticate_user!
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `bin/console` for an interactive prompt that will allow you to experiment.

To run tests, you will need postgres setup and configured correctly (see
`spec/database.yml`).

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and
then run `bundle exec rake release` to create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org][8].

## Contributing

1. Fork it ( https://github.com/mcordell/grape_token_auth/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[1]: https://github.com/lynndylanhurley/ng-token-auth
[2]: https://github.com/lynndylanhurley/j-toker
[3]: https://github.com/lynndylanhurley/devise_token_auth
[4]: https://github.com/intridea/grape
[5]: https://github.com/mcordell/grape_devise_token_auth
[6]: https://github.com/lynndylanhurley
[7]: https://github.com/lynndylanhurley/devise_token_auth#conceptual
[8]: https://rubygems.org
[9]: https://github.com/hassox/warden
[10]: https://github.com/mcordell/grape_token_auth/milestones/Devise%20Token%20Auth%20Functional%20Parity
