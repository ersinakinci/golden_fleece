# Golden Fleece 🐑

Easy schemas for JSON columns in your Ruby data models. Currently supports ActiveRecord/ActiveModel >= 3.0 (i.e., Rails 3, 4 and 5).

Golden Fleece lets you define a schema for your Ruby data models, which can be used to do fun things:

- Validate JSON data types and formats
- Normalize JSON data
- Provide default values within nested JSON

It's like [JSON Schema](http://json-schema.org/) but more opinionated and, in our opinion, more straightforward to use.

🍊 Battle-tested at Instacart.

## Quick start

Add this line to your application's Gemfile:

```ruby
gem 'golden_fleece'
```

Then `include GoldenFleece::Model` and define schemas in your data models:

```ruby
class Person < ActiveRecord::Base
  include GoldenFleece::Model

  fleece do
    define_schemas :profile, {
      first_name: { type: :string },
      last_name:  { types: [:string, :null] },
      zip_code:   { type: :string, default: '90210' }
    }
  end
end

person.profile['first_name'] = 'Jane'
person.profile['last_name'] = nil
person.valid?        # true
person.export_fleece # { profile: { 'first_name' => 'Jane', 'last_name' => nil, 'zip_code' => '90210' } }

person.profile.delete 'first_name'
person.valid? # false
```

## Usage

### Schemas

Golden Fleece's core concept is the schema. A schema is a structure that defines what your JSON columns should look like and are defined within the `fleece` block on a model using `define_schemas`:

```ruby
class Person < ActiveRecord::Base
  include GoldenFleece::Model

  fleece do
    define_schemas :profile, {
      first_name: { type: :string },
      last_name:  { types: [:string, :null] },
      zip_code:   { type: :string, default: '90210' }
    }
  end
end
```

The above example defines a schema on the `Person` model's `profile` column and introduces certain restraints on the `first_name`, `last_name` and `zip_code` fields within the `profile` column's JSON object. Note that Golden Fleece assumes that all columns with a schema are valid JSON objects.

Note that any keys added to a JSON object that aren't listed in the schema are invalid:

```ruby
define_schemas :profile, {
  first_name: ...,
  last_name: ...,
  zip_code: ...,
}

person.profile['address'] = '123 Nottingham Way'
person.valid? # false
```

### Types

Type checks are introduced with the `type` or `types` option (both are interchangeable):

```ruby
define_schemas :profile, {
  zip_code: { type: :string }
}

person.profile['zip_code'] = 90210
person.valid? # false
```

Note that passing `:null` to `type`/`types` allows the field to be nullable.

### Defaults

Defaults defined on schemas will fill in `nil` values in your JSON columns when validating and exporting. Defaults are safe and will _never_ backfill your model's columns:

```ruby
define_schemas :profile, {
  zip_code: { type: :string, default: '90210' }
}

person.profile['zip_code'] = nil
person.valid?              # true
person.export_fleece       # { profile: { 'zip_code' => '90210' } }
person.profile['zip_code'] # nil
```

In addition to static values, you can use Proc's to dynamically generate defaults at runtime:

```ruby
define_schemas :profile, {
  zip_code: { type: :string, default: -> record { record.closest_location.zip_code } }
}

person.export_fleece # { profile: { 'zip_code' => '94131' } }
```

### Getters

Top-level keys in your JSON columns can automatically be mapped as getters on your data model's instances using `define_getters`. Getters are safe and will _never_ override any preexisting instance methods:

```ruby
define_schemas :profile, {
  zip_code: ...,
  class: ...
}
define_getters :profile

person.zip_code            # '90210'
person.profile['zip_code'] # nil

person.profile['class'] = 'Freshman'
person.class # Person
```

Note that getters will return the exported value of your JSON key rather than the raw value.

### Normalizers

Normalizers are Procs that normalize your data before validating, exporting or saving:

```ruby
define_normalizers({
  cast_string: -> record, value { value.to_s }
})

define_schemas :profile, {
  zip_code: { type: :string, normalizer: :cast_string }
}

person.profile['zip_code'] = 90210
person.profile['zip_code'] # 90210
person.zip_code            # '90210'
person.valid?              # true

person.save
person.profile['zip_code'] # '90210'
person.zip_code            # '90210'
```

Note that multiple normalizers can be chained with `normalizers`:

```ruby
define_normalizers({
  cast_string: ...,
  sha1: -> record, value { sha1(value) }
})

define_schemas :profile, {
  zip_code: { type: :string, normalizers: [:cast_string, :sha1] }
}

person.profile['zip_code'] = 90210
person.zip_code            # '2b02dbc1030b278245b2b9cb11667eebf7275a52'
```

Be careful! Normalizers can change your data when saving your record. Make sure your normalizer doesn't make invalid assumptions about types, etc.:

```ruby
define_normalizers({
  csv_to_array: -> record, value { value.to_s.split(/\s*,\s*/) }
})

define_schemas :settings, {
  important_ids: { type: :array, normalizer: :csv_to_array }
}

define_getters :settings

person.profile['important_ids'] = '1001, 1002,1003'
person.important_ids # [1001, 1002, 1003] (as expected)
person.save          # normalizer persists the array in place of the CSV string
person.important_ids # [0, 1002, 1003] (not expected! normalizer is trying to convert your array to a string, then splitting it on commas)
```

### Formats

Formats are Procs that can be used to enforce complex validations:

```ruby
define_formats({
  zip_code: -> record, value { raise ArgumentError.new("must be a valid ZIP code") unless value =~ /^[0-9]{5}(?:-[0-9]{4})?$/ }
})

define_schemas :profile, {
  zip_code: { type: :string, format: :zip_code }
}

person.profile['zip_code'] = '90210'      # person.valid? == true
person.profile['zip_code'] = '90210-1234' # person.valid? == true
person.profile['zip_code'] = '90210-12'   # person.valid? == false
person.errors.messages                    # "Invalid format at '/zip_code' on column 'profile': must be a valid ZIP code"
```

Note that unlike types and normalizers, you can only use one format at a time for each schema.

### Nested JSON

Schemas can be nested with `subschemas`:

```ruby
define_schemas :profile, {
  address: { type: :object, subschemas: {
      number: { type: :number },
      street: { type: :string },
      zip_code: { type: :string, default: '90210' }
    }
  }
}

person.profile['address'] # nil
person.address            # { number: nil, street: nil, zip_code: '90210' }
person.valid?             # false
```

### Exporting

TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Using Golden Fleece with other ORM's

TODO

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/earksiinni/golden_fleece. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
