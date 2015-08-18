# Contributing

Fork, then clone the repo:

    git clone git@github.com:your-username/grape_token_auth.git

Set up your machine:

    ./bin/setup

Make sure the tests pass:

    ./bin/rspec

Make your changes and add tests for your change. I use [rubocop][rc] with the default
style guide for consistency.

Make sure the tests pass before committing:

    ./bin/rspec

##Git committing

I prefer short, atomic commits. Obviously, this isn't a deal breaker but I
believe it makes for a better repo. When writing git messages, refer to this
[great post by Tim Pope][gc]. As a small addendum, I try to begin each message
with one of the following words:

- Add
- Modify
- Re-factor
- Fix
- Remove
- Tidy
- Update

I find this expresses the intent of the commit and also helps keep things
atomic. I picked this trick up from this
[post](https://github.com/rails/rails/blob/master/CONTRIBUTING.md).


Push to your fork and [submit a pull request][pr].

[gc]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[rc]: https://github.com/bbatsov/rubocop
[pr]: https://github.com/mcordell/grape_token_auth/compare/
