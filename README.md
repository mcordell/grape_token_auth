# GrapeTokenAuth
[![Gem Version][17]][18] [![Code Climate GPA][11]][12] [![Test Coverage][13]][14] [![Circle CI][15]][16]

GrapeTokenAuth is a token authentication solution for grape. It is compatible
with [ng-token-auth][1] (for _angular_) and [j-toker][2] (for _jQuery_), and is
meant as a [grape][4] (rather than _rails_) version of [devise_token_auth][3]. As
such, this project is built entirely upon _grape_ and [warden][9] and avoids the
need for _rails_. However, it has built in compatibility for [devise][devise] if
you are looking to mount a grape app within your rails app. Finally, If you are
placing a grape app within an existing _rails_ + _devise\_token\_auth_ app you might
be interested in [grape_devise_token_auth][5].

This gem is a port of [devise_token-auth][4] written by [Lyann Dylan Hurley][6]
and [the team of contributors][dta-contributors]. That team does great work and
the [conceptual section on that gem][7] is highly recommended reading.

_Philosophy_

This gem aims to maintain a small direct dependency footprint. As such, it
currently depends only on _grape_, _warden_, _mail_, and _bcrypt_. In the
future, the hope is to break this gem up into modules so that you can be even
more selective on the code and dependencies that are included.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grape_token_auth'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install grape_token_auth
```

## Quick-Start Setup

This is the minimum setup to get _GrapeTokenAuth_ running. For a more
detailed walkthrough, you can refer to this [blog post][gta-setup], the [demo
repo][demo-repo], and the [wiki][gta-wiki]. Setup has 4 parts:

1. [Middleware Setup](#middlewaresetup)
2. [Model/ORM setup](#modelormsetup)
3. [Grape Token Auth configuration](#grapetokenauthconfiguration)
4. [Mounting Authentication APIs](#mountingauthenticationapis)

###Middleware setup

_GrapeTokenAuth_ requires setting up _warden_ middleware in order to function
properly. In a simple _rack_ environment this is usually as easy as adding the
following to the `config.ru`:

```ruby
# config.ru

require 'warden'
require 'grape_token_auth'

## Setup session middleware (E.g. Rack::Session::Cookie)

GrapeTokenAuth.setup_warden!(self)

run YourGrapeAPI
```

In _rails_, you will need to setup warden as so:

```ruby
# application.rb

config.middleware.insert_after ActionDispatch::Flash, Warden::Manager do |manager|
  manager.failure_app = GrapeTokenAuth::UnauthorizedMiddleware
  manager.default_scope = :user
end
```

### Model/ORM setup

Include the module for your ORM within the model classes. At the moment, only
ActiveRecord is supported but other ORMs are planned. Your model must
contain a text-type field called `tokens`.

####ActiveRecord

```ruby
class User < ActiveRecord::Base
  include GrapeTokenAuth::ActiveRecord::TokenAuth
end
```

### Grape Token Auth Configuration

GTA does not make guesses about what scopes and user classes you are using, you
must define them before the Grape API is loaded. In _rails_ this could be in an
initializer, for a rack app run the setup before the API class definitions.

To define mappings, the scope is the key of the mapping hash, and the value is the
model to which the scope is mapped. For the above user class this would be:

```ruby
GrapeTokenAuth.setup! do |config|
	config.mappings = { user: User }
	config.secret   = 'THIS MUST BE A LONG HEX STRING'
end
```

**Note on Secret**: generate a unique secret using `rake secret` in a rails app
or via [these directions][secret].

In addition, if you are using the mail features in grape_token_auth you will
want to set the appropriate configuration options. See the [mail wiki page][mail] for
more information.


### Mounting authentication APIs

In order to use a given feature of GrapeTokenAuth, the corresponding API must be
mounted. This can be accomplished in your grape app by first including the mount
helpers:


```ruby
class TestApp < Grape::API
  format :json

  include GrapeTokenAuth::MountHelpers

  #...
end
```

Then you can use the individual helpers to mount a given GTA API:

```ruby
class TestApp < Grape::API
  # ...

  mount_registration(to: '/auth', for: :user)
  mount_sessions(to: '/auth', for: :user)
  mount_token_validation(to: '/auth', for: :user)
  mount_confirmation(to: '/auth', for: :user)

  # ...
end
```

The first line indicates the _GrapeTokenAuth_ registration API will be mounted
to '/auth' relative to the location where the TestApp is mounted. Presuming that
TestApp is being run at root, registration endpoints will be at `/auth`. Also,
we are defining the scope that these endpoints pertain to (user). **Important**
the scope must be defined in the [configuration
step](#grapetokenauthconfiguration).

A table of the various APIs and their associated helpers follows:

| API | helper | description |
| --- | --- | --- |
| Registration         | `mount_registration` | used to register new 'email' type users |
| Session              | `mount_sessions`     | used to login 'email' type users        |
| Confirmation | `mount_confirmation` | used to confirm 'email' users new emails |
| TokenValidation      | `mount_token_validation`      | used to tokens for all type users        |
| OmniAuth | `mount_omniauth` | used to register/login omniauth users, requires the OmniAuthCallback API |
| OmniAuthCallback | `mount_omniauth_callbacks` |  used to register/login omniauth users, requires the OmniAuth API|
| PasswordReset | `mount_password_reset` | used to issue password resets for forgotten passwords|

## Usage

First, include the `TokenAuthentication` module in the _grape_ API you want to
enforce authentication on.

```ruby
class TestApp < Grape::API
  # ...

  include GrapeTokenAuth::TokenAuthentication

  # ...
end
```

### Enforcing authentication on an endpoint

In any _grape_ endpoint you can call `authenticate_{SCOPE}!` to enforce
authentication on that endpoint. For instance, the following:

```ruby
get '/' do
  authenticate_user!
  present Post.all
end
```

will authenticate against the `:user` scope when trying to GET the `/` route.


### Enforcing authentication on all endpoints

Alternatively, if you want to protect all of the endpoints in an API, place
the authentication call in a `before_filter`, like so:

```ruby
class TestApp < Grape::API
  before do
    :authenticate_user!
  end
end
```

### Overriding resource presentation

It is often desirable to use serialization libraries such as
ActiveModelSerializers or Grape's entities. Previously, GTA would simply wrap
the resource in a hash under the :data key. This did not integrate well with the
above serialization solutions. This behavior can now be controlled and modified
by using a different `ResourcePreparer`. A ResourcePreparer should implement a
class method called `prepare` which accepts an instance of the resource and returns
an object to be serialized/passed to grape's `present` method. An example, that
retains the default behavior can be found in the
[DefaultPreparer][default_preparer]. As an example,
if you wanted to pass the resource directly through to the present command, this
could be achieved with:

```ruby
class UntouchedPreparer
  def self.prepare(resource)
    resource
  end
end

GrapeTokenAuth.configure do |config|
  config.resource_preparer = UntouchedPreparer
end
```

*Warning* : ng\_token\_auth expects the resource nested within the 'data' key of
a JSON object (hence the default behavior). Breaking this convention may break
compatibility with ng\_token\_auth.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `bin/console` for an interactive prompt that will allow you to experiment.

To run tests, you will need postgres to be setup and configured correctly.  Run
`rake db:setup` to create the test db and `rake db:reset` to reset the db.


## Contributing

[See CONTRIBUTING.md][contributing]

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
[11]: https://codeclimate.com/github/mcordell/grape_token_auth/badges/gpa.svg
[12]: https://codeclimate.com/github/mcordell/grape_token_auth
[13]: https://codeclimate.com/github/mcordell/grape_token_auth/badges/coverage.svg
[14]: https://codeclimate.com/github/mcordell/grape_token_auth/coverage
[15]: https://circleci.com/gh/mcordell/grape_token_auth.svg?style=svg
[16]: https://circleci.com/gh/mcordell/grape_token_auth
[17]: https://badge.fury.io/rb/grape_token_auth.svg
[18]: https://badge.fury.io/rb/grape_token_auth
[contributing]: https://github.com/mcordell/grape_token_auth/blob/master/CONTRIBUTING.md
[gta-wiki]: https://github.com/mcordell/grape_token_auth/wiki
[demo-repo]: https://github.com/mcordell/grape_token_auth_demo
[gta-setup]: http://blog.mikecordell.com/grape-token-auth/2015/09/15/setting-up-authentication-on-a-grape-api-with-grapetokenauth.html
[secret]: http://www.jamesbadger.ca/2012/12/18/generate-new-secret-token/
[dta-contributors]: https://github.com/lynndylanhurley/devise_token_auth#callouts
[devise]: https://github.com/plataformatec/devise
[mail]: https://github.com/mcordell/grape_token_auth/wiki/Email
[default_preparer]: https://github.com/mcordell/grape_token_auth/blob/fa7268e91dfbecdee085cdef8a27a7bd49f0908b/lib/grape_token_auth/resource/default_preparer.rb
