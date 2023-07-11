# SsmConfig

* ActiveRecord
  - Any file in ActiveRecord with model name `SsmConfigRecord` can be accessed by calling `SsmConfig.file_name`
  - All rows with the corresponding file name will be parsed into a hash
* `config` directory 
  - If file is not found in `SsmConfigRecord` (or the ActiveRecord doesn't exist), `SsmConfig` looks in the `config` directory
  - Any YAML file in the directory with the corresponding file name will be parsed into a hash

These two are exclusive, with the former prioritized: i.e., the gem will look in the ActiveRecord model first, and then in the `config` directory if no such file is found.
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ssm_config'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ssm_config

## Setup

To utilize ActiveRecords, create the following model:
```
rails generate model SsmConfigRecord file:string:index accessor_keys:string value:string datatype:string
```

The supported datatypes are `[string, integer, boolean, float]`. The field `datatype` should contain the character that corresponds to the first character of the datatype (so one of `[s, i, b, f]`). This field is not case-sensitive (the gem also only checks the first character of `datatype`). Booleans should also be one of `[t, f]`, corresponding to `true` and `false`. Similarly, this is not case-sensitive and only the first character of the value (given the datatype is a boolean) will be checked.

An invalid entry will throw an exception (as well as an invalid boolean entry). 

When migrating a file to the ActiveRecord, it is important to correctly input the accessor keys. The field `accessor_keys` represents a hashkey corresponding to a value in the hash: for the sequence of keys used to access a value, the corresponding accessor key will be the keys concatentated with a comma delimiter. For example, if `hash[:key1][:key2][:key3] = value`, the corresponding accessor key would be the string `"key1,key2,key3"`. In the case that there is an array, we include the index embraced by brackets. Consider the following hash:

```yml
any:
  build:
    docker:
      - image: value1
    steps:
      - value2
      - run: value3
```
The accessor keys for `value1`, `value2`, and `value3` would be `"build,docker,[0],image"`, `"build,steps,[0]"`, and `"build,steps,[1],run"`, respectively.

⚠️ **NOTE:** ⚠️ There should be no file name called `cache`, as this will call a method of the `SsmConfig` class. Also, all values read from the table will be strings.
## Usage


Given the following rows in `SsmConfigRecord`:

| file | accessor_keys | value |
| :---: | :------------: | :---: |
| eft | days_to_enter_bank_account,default | 3 |
| eft | days_to_enter_bank_account,company1,[0] | 2 |
| eft | days_to_enter_bank_account,company2 | 4|

```ruby
SsmConfig.eft
=> {"days_to_enter_bank_account"=>{"default"=>3, "company1"=>[2], "company2"=>4}}
```
`SsmConfig` will always reconstruct the hash using all the rows with the corresponding file name. In the case that no such row exists, `SsmConfig` will look for `config/foo.yml`. For example, given `config/eft.yml`,

```yml
any:
  days_to_enter_bank_account:
    default: 3
    company1:
      - 2
    company2: 4
```
```ruby
SsmConfig.eft
=> {"days_to_enter_bank_account"=>{"default"=>3, "company1"=>[2], "company2"=>4}}
```

This search will be exclusive: i.e., if any row exists in the table then the gem will not look in `config`.
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To develop and test locally, include a path for your gem in the Gemfile of the desired application, i.e.,
```
gem 'ssm_config', path: 'path'
```

## Release to RubyGems

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
To do so, you need a RubyGems account and [to be listed as an owner](https://rubygems.org/gems/ssm_config/owners).
In the process, after pushing the tag, the console will hang. You will need to enter your RubyGems login and then its password.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bodyshopbidsdotcom/ssm_config. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

