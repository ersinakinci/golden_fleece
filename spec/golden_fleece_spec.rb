require "spec_helper"
require "active_model"
require "active_support/core_ext/hash"
require "golden_fleece/schema"

RSpec.describe GoldenFleece do
  class MockModel
    include ::ActiveModel::AttributeMethods
    include ::ActiveModel::Dirty
    include ::ActiveModel::Validations
    extend ::ActiveModel::Callbacks

    attr_reader :errors

    # ActiveModel >= 4.0
    # define_attribute_methods :settings
    # ActiveModel ~> 3.0
    define_attribute_methods [:settings]
    define_model_callbacks :save

    def initialize
      @errors = ::ActiveModel::Errors.new(self)
      @settings = {}
    end

    def settings
      @settings
    end

    def settings=(val)
      settings_will_change! unless val == @settings
      @settings = val
    end

    def read_attribute(attribute)
      send(attribute)
    end

    def write_attribute(attribute, value)
      send("#{attribute}=", value)
    end

    def save
      run_callbacks :save do
        # ActiveModel >= 4.0
        # changes_applied
        # ActiveModel ~> 3.0
        @previously_changed = changes
        @changed_attributes.clear
      end
    end

    def self.reset
      # Reset getters
      fleece_context.schemas.each do |attribute, attribute_schema|
        attribute_schema.each do |field, field_schema|
          remove_method(field) if instance_methods(false).include? field
        end
      end

      # Reset validate and save callbacks
      # ActiveModel >= 5.0
      # __callbacks.each do |_, cb|
      #   cb.clear
      # end
      # ActiveModel < 5.0
      self.reset_callbacks :validate
      self.reset_callbacks :save

      # Reload Golden Fleece
      include GoldenFleece::Model
    end

    include GoldenFleece::Model
  end

  let(:model) { MockModel.new }

  after do
    MockModel.reset
  end

  it "has a version number" do
    expect(GoldenFleece::VERSION).not_to be nil
  end

  it 'allows one to define schemas' do
    MockModel.fleece {
      define_schemas :settings, {
        first_name: { type: :string }
      }
    }

    expect(MockModel.fleece_context.schemas[:settings][:first_name]).not_to be_nil
  end

  it 'allows one to define getters' do
    MockModel.fleece {
      define_schemas :settings, {
        first_name: { type: :string }
      }
      define_getters :settings
    }

    expect(model).to respond_to(:first_name)
  end

  it 'allows one to define multiple schemas at the same time' do
    MockModel.fleece {
      define_schemas :settings, {
        address: { type: :string, default: 'Default address' },
        phone_number: { types: [:string, :number], default: 'Default phone number' }
      }
    }

    expect(MockModel.fleece_context.schemas[:settings][:address]).not_to be_nil
    expect(MockModel.fleece_context.schemas[:settings][:phone_number]).not_to be_nil
  end

  it 'allows one to set default values for schemas' do
    MockModel.fleece {
      define_schemas :settings, {
        first_name: { type: :string, default: 'Default first name' }
      }
      define_getters :settings
    }

    expect(model.first_name).to eq('Default first name')
  end

  it 'returns true when validation succeeds' do
    expect(model.valid?).to eq(true)
  end

  it 'validates keys' do
    MockModel.fleece {
      define_schemas :settings, {
        first_name: { type: :string, default: 'Default first name' }
      }
    }

    model.settings = { 'invalid_schema' => 'blah' }

    expect(model.valid?).to eq false
    expect(model.errors.messages[:settings].count).to eq 1
  end

  it 'validates types' do
    MockModel.fleece {
      define_schemas :settings, {
        first_name: { type: :string, default: 'Default first name' }
      }
    }

    model.settings = { 'first_name' => 3 }

    expect(model.valid?).to eq false
    expect(model.errors.messages[:settings].count).to eq 1
  end

  it 'validates types when there are multiple allowed types' do
    MockModel.fleece {
      define_schemas :settings, {
        last_name: { types: [:string, :null] }
      }
    }

    model.settings = { 'last_name' => nil }

    expect(model.valid?).to eq true
  end

  it 'validates formats' do
    MockModel.fleece {
      define_formats({
        zip_code: -> value { raise ArgumentError.new("must be a valid ZIP code") unless value =~ /^[0-9]{5}$/ }
      })
      define_schemas :settings, {
        zip_code: { type: :string, format: :zip_code }
      }
    }

    model.settings = { 'zip_code' => 'abc' }

    expect(model.valid?).to eq false
    expect(model.errors.messages[:settings].count).to eq 1
    expect(model.errors.messages[:settings][0]).to include "Invalid format"
  end

  it 'validates nested subschemas (failure)' do
    MockModel.fleece {
      define_schemas :settings, {
        location: { type: :object, subschemas: {
            city: { type: :string },
            zip_code: { type: :string }
          }
        }
      }
    }

    model.settings = { 'location' => { 'city' => 'San Fransokyo' } }

    expect(model.valid?).to eq false
    expect(model.errors.messages[:settings].count).to eq 1
    expect(model.errors.messages[:settings][0]).to include "Invalid type"
  end

  it 'validates nested subschemas (success)' do
    MockModel.fleece {
      define_schemas :settings, {
        location: { type: :object, subschemas: {
            city: { type: :string },
            zip_code: { type: :string }
          }
        }
      }
    }

    model.settings = {
      'location' => {
        'city' => 'San Fransokyo',
        'zip_code' => '94151'
      }
    }

    expect(model.valid?).to eq true
    expect(model.errors.messages[:settings]).to be_nil
  end

  it 'validates arrays (success)' do
    MockModel.fleece {
      define_schemas :settings, {
        warehouse_ids: { type: :array },
        user_ids: { type: :array, default: [] }
      }
    }

    model.settings = {
      'warehouse_ids' => [1, 2, 3, 4]
    }

    expect(model.valid?).to eq true
    expect(model.errors.messages[:settings]).to be_nil
  end

  it 'validates arrays (failure)' do
    MockModel.fleece {
      define_schemas :settings, {
        warehouse_ids: { type: :array }
      }
    }

    expect(model.valid?).to eq false
    expect(model.errors.messages[:settings].count).to eq 1
    expect(model.errors.messages[:settings][0]).to include "Invalid type"
  end

  it 'exports fleece' do
    MockModel.fleece do
      define_schemas :settings, {
        first_name: { type: :string },
        last_name: { type: :string, default: 'Else' },
        location: { type: :object, subschemas: {
            city: { type: :string, default: 'San Fransokyo' }
          }
        }
      }
    end

    model.settings = { 'first_name' => 'Someone' }

    expect(model.export_fleece).to contain_exactly(
      [
        :settings,
        {
          'first_name' => 'Someone',
          'last_name' => 'Else',
          'location' => { 'city' => 'San Fransokyo' }
        }
      ]
    )
  end

  it 'casts boolean-ish values' do
    MockModel.fleece do
      define_schemas :settings, {
        happy?: { type: :boolean },
        sad?: { type: :boolean },
        real_happy?: { type: :boolean },
        real_sad?: { type: :boolean },
        other_feel: { type: :boolean },
        other_feel_default: { type: :boolean, default: false }
      }
      define_getters :settings
    end

    model.settings = {
      'happy?' => '1',
      'sad?' => 'false',
      'real_happy?' => true,
      'real_sad?' => false,
    }
    model.save

    expect(model.valid?).to eq(false)
    expect(model.happy?).to eq(true)
    expect(model.sad?).to eq(false)
    expect(model.real_happy?).to eq(true)
    expect(model.real_sad?).to eq(false)
    expect(model.other_feel).to eq(nil)
    expect(model.other_feel_default).to eq(false)
    expect(model.settings['happy?']).to eq(true)
    expect(model.settings['sad?']).to eq(false)
    expect(model.settings['real_happy?']).to eq(true)
    expect(model.settings['real_sad?']).to eq(false)
    expect(model.settings['other_feel']).to eq(nil)
    expect(model.settings['other_feel_default']).to eq(false)
  end

  it 'normalizes values using normalizer (single)' do
    MockModel.fleece do
      define_normalizers({
        csv_to_array: -> record, value { value.is_a?(String) ? value.split(/\s*,\s*/) : value }
      })
      define_schemas :settings, {
        important_ids: { type: :array, normalizer: :csv_to_array }
      }
      define_getters :settings
    end

    model.settings = { 'important_ids' => '1000,1001, 1002' }
    model.save

    expect(model.important_ids).to be_an Array
    expect(model.important_ids).to eq(['1000', '1001', '1002'])
    expect(model.settings['important_ids']).to be_an Array
    expect(model.settings['important_ids']).to eq(['1000', '1001', '1002'])
  end

  it 'normalizes values using normalizers (multiple)' do
    MockModel.fleece do
      define_normalizers({
        csv_to_array: -> record, value { value.is_a?(String) ? value.split(/\s*,\s*/) : value },
        integer_array: -> record, value { Array.wrap(value).map { |e| e.to_i } }
      })
      define_schemas :settings, {
        important_ids: { type: :array, normalizers: [:csv_to_array, :integer_array] }
      }
      define_getters :settings
    end

    model.settings = { 'important_ids' => '1000,1001, 1002' }
    model.save

    expect(model.important_ids).to be_an Array
    expect(model.important_ids).to eq([1000, 1001, 1002])
    expect(model.settings['important_ids']).to be_an Array
    expect(model.settings['important_ids']).to eq([1000, 1001, 1002])
  end

  it 'allows defining and redefining schemas individually' do
    MockModel.fleece do
      define_schemas :settings, {
        first_name: { type: :string, default: "Default first name" },
        last_name: { type: :string },
        location: { type: :object, subschemas: {
          zip_code: { type: :string },
          address: { type: :string }
        } }
      }
    end

    # Define new schema
    MockModel.fleece do
      define_schemas :settings, {
        middle_name: { type: :string }
      }
    end

    # Redefine old schema
    MockModel.fleece do
      define_schemas :settings, {
        location: { type: :string }
      }
    end

    model.settings = { 'last_name' => 'Last name' }

    expect(model.valid?).to eq(false)
    expect(model.errors.messages[:settings].count).to eq(2)
    expect(MockModel.fleece_context.schemas[:settings][:first_name].types).to eq([GoldenFleece::Definitions::TYPES[:string]])
    expect(MockModel.fleece_context.schemas[:settings][:middle_name].types).to eq([GoldenFleece::Definitions::TYPES[:string]])
    expect(MockModel.fleece_context.schemas[:settings][:location].types).to eq([GoldenFleece::Definitions::TYPES[:string]])
  end

  it 'exports defaults within nested schemas that already have a corresponding partially-complete persisted JSON object' do
    MockModel.fleece do
      define_schemas :settings, {
        location: { type: :object, subschemas: {
          zip_code: { type: :string },
          address: { type: :string, default: '123 Default St.' }
        } }
      }
    end

    # Note that the address isn't persisted, but the default address should be
    # merged into the persisted JSON, appearing in the exported hash
    model.settings = { 'location' => { 'zip_code' => '12345' } }
    model.save

    expect(model.export_fleece[:settings]['location']['zip_code']).to eq('12345')
    expect(model.export_fleece[:settings]['location']['address']).to eq('123 Default St.')
  end

  it 'expects all exported keys to be strings' do
    MockModel.fleece do
      define_schemas :settings, {
        location: { type: :object, subschemas: {
          zip_code: { type: :string },
          address: { type: :string, default: '123 Default St.' }
        } }
      }
    end

    expect(model.export_fleece[:settings]).to include('location')
    expect(model.export_fleece[:settings]['location']).to include('zip_code')
    expect(model.export_fleece[:settings]['location']).to include('address')
  end

  it 'allows defining schema with strings' do
    MockModel.fleece do
      define_schemas :settings, {
        '2legit2quit' => { type: :object, subschemas: {
          '3togetready' => { type: :string },
          '4togo' => { type: :string, default: 'hi' }
        } }
      }
    end

    expect(model.export_fleece).to contain_exactly(
      [
        :settings,
        {
          '2legit2quit' => {
            '3togetready' => nil,
            '4togo' => 'hi'
          }
        }
      ]
    )
  end
end
