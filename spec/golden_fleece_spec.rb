require "spec_helper"
require "active_model"
require "active_support/core_ext/hash"
require "golden_fleece/schema"

RSpec.describe GoldenFleece do
  class MockModel
    include ::ActiveModel::Model
    include ::ActiveModel::AttributeMethods
    include ::ActiveModel::Dirty
    include ::ActiveModel::Validations
    extend ::ActiveModel::Callbacks

    attr_reader :errors

    define_attribute_methods :settings
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
        changes_applied
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
      __callbacks.each do |_, cb_chain|
        cb_chain.clear
      end

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

  it 'validates nested subconfigs (failure)' do
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

  it 'validates nested subconfigs (success)' do
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
    expect(model.errors.messages[:settings].count).to eq 0
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
    expect(model.errors.messages[:settings].count).to eq 0
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

  it 'exports configs' do
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
          first_name: 'Someone',
          last_name: 'Else',
          location: { city: 'San Fransokyo' }
        }
      ]
    )
  end

  it 'casts boolean-ish values' do
    MockModel.fleece do
      define_schemas :settings, {
        happy?: { type: :boolean }
      }
      define_getters :settings
    end

    model.settings = { 'happy?' => '1' }
    model.save

    expect(model.valid?).to eq(true)
    expect(model.happy?).to eq(true)
    expect(model.settings['happy?']).to eq(true)
  end

  it 'normalizes values using normalizer (single)' do
    MockModel.fleece do
      define_normalizers({
        csv_to_array: -> record, value { value.to_s.split(/\s*,\s*/) }
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
        csv_to_array: -> record, value { value.to_s.split(/\s*,\s*/) },
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
end
