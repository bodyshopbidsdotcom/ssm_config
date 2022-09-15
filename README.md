# SsmConfig

Any config YAML in the config directory can be accessed by calling `SsmConfig.config_name`.
For example, if you wish to access `config/foo.yml`, just call `SsmConfig.foo` from anywhere in the app. The YAML will be parsed
into a hash.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ssm_config'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ssm_config

## Usage

Given `config/eft.yml`:
```yml
any:
  days_to_enter_bank_account:
    default: 3
    company1: 2
    company2: 4
```

```ruby
SsmConfig.eft
=> {"days_to_enter_bank_account"=>{"default"=>3, "company1"=>2, "company2"=>4}}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Release to RubyGems

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
To do so, you need a RubyGems account and [to be listed as an owner](https://rubygems.org/gems/ssm_config/owners).
In the process, after pushing the tag, the console will hang. You will need to enter your RubyGems login and then its password.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bodyshopbidsdotcom/ssm_config. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

