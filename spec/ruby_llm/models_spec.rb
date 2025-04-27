# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe RubyLLM::Models do
  include_context 'with configured RubyLLM'

  describe 'filtering and chaining' do
    it 'filters models by provider' do # rubocop:disable RSpec/MultipleExpectations
      openai_models = RubyLLM.models.by_provider('openai')
      expect(openai_models.all).to all(have_attributes(provider: 'openai'))

      # Can chain other filters and methods
      expect(openai_models.chat_models).to be_a(described_class)
    end

    it 'chains filters in any order with same result' do
      # These two filters should be equivalent
      openai_chat_models = RubyLLM.models.by_provider('openai').chat_models
      chat_openai_models = RubyLLM.models.chat_models.by_provider('openai')

      # Both return same model IDs
      expect(openai_chat_models.map(&:id).sort).to eq(chat_openai_models.map(&:id).sort)
    end

    it 'supports Enumerable methods' do # rubocop:disable RSpec/MultipleExpectations
      # Count models by provider
      provider_counts = RubyLLM.models.group_by(&:provider)
                               .transform_values(&:count)

      # There should be models from at least OpenAI and Anthropic
      expect(provider_counts.keys).to include('openai', 'anthropic')

      # Select only models with vision support
      vision_models = RubyLLM.models.select(&:supports_vision)
      expect(vision_models).to all(have_attributes(supports_vision: true))
    end
  end

  describe 'finding models' do
    it 'finds models by ID' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      # Find the default model
      model_id = RubyLLM.config.default_model
      model = RubyLLM.models.find(model_id)
      expect(model.id).to eq(model_id)

      # Find a model with chaining
      if RubyLLM.models.by_provider('openai').chat_models.any?
        openai_chat_id = RubyLLM.models.by_provider('openai').chat_models.first.id
        found = RubyLLM.models.by_provider('openai').find(openai_chat_id)
        expect(found.id).to eq(openai_chat_id)
        expect(found.provider).to eq('openai')
      end
    end

    it 'raises ModelNotFoundError for unknown models' do
      expect do
        RubyLLM.models.find('nonexistent-model-12345')
      end.to raise_error(RubyLLM::ModelNotFoundError)
    end
  end

  describe '#find' do
    it 'prioritizes exact matches over aliases' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      # This test covers the case from the issue
      chat_model = RubyLLM.chat(model: 'gemini-2.0-flash')
      expect(chat_model.model.id).to eq('gemini-2.0-flash')

      # Even with provider specified, exact match wins
      chat_model = RubyLLM.chat(model: 'gemini-2.0-flash', provider: 'gemini')
      expect(chat_model.model.id).to eq('gemini-2.0-flash')

      # Only use alias when exact match isn't found
      chat_model = RubyLLM.chat(model: 'claude-3')
      expect(chat_model.model.id).to eq('claude-3-sonnet-20240229')
    end
  end

  describe '#refresh!' do
    it 'updates models and returns a chainable Models instance' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      # Use a temporary file to avoid modifying actual models.json
      temp_file = Tempfile.new(['models', '.json'])
      allow(File).to receive(:expand_path).with('models.json', any_args).and_return(temp_file.path)

      begin
        # Refresh and chain immediately
        chat_models = RubyLLM.models.refresh!.chat_models

        # Verify we got results
        expect(chat_models).to be_a(described_class)
        expect(chat_models.all).to all(have_attributes(type: 'chat'))

        # Verify we got models from at least OpenAI and Anthropic
        providers = chat_models.map(&:provider).uniq
        expect(providers).to include('openai', 'anthropic')
      ensure
        temp_file.close
        temp_file.unlink
      end
    end

    it 'works as a class method too' do # rubocop:disable RSpec/ExampleLength
      temp_file = Tempfile.new(['models', '.json'])
      allow(File).to receive(:expand_path).with('models.json', any_args).and_return(temp_file.path)

      begin
        # Call class method
        described_class.refresh!

        # Verify singleton instance was updated
        expect(RubyLLM.models.all.size).to be > 0
      ensure
        temp_file.close
        temp_file.unlink
      end
    end
  end

  describe '#embedding_models' do
    it 'filters to only embedding models' do # rubocop:disable RSpec/MultipleExpectations
      embedding_models = RubyLLM.models.embedding_models

      expect(embedding_models).to be_a(described_class)
      expect(embedding_models.all).to all(have_attributes(type: 'embedding'))
      expect(embedding_models.all).not_to be_empty
    end
  end

  describe '#audio_models' do
    it 'filters to only audio models' do # rubocop:disable RSpec/MultipleExpectations
      audio_models = RubyLLM.models.audio_models

      expect(audio_models).to be_a(described_class)
      expect(audio_models.all).to all(have_attributes(type: 'audio'))
    end
  end

  describe '#image_models' do
    it 'filters to only image models' do # rubocop:disable RSpec/MultipleExpectations
      image_models = RubyLLM.models.image_models

      expect(image_models).to be_a(described_class)
      expect(image_models.all).to all(have_attributes(type: 'image'))
      expect(image_models.all).not_to be_empty
    end
  end

  describe '#by_family' do
    it 'filters models by family' do # rubocop:disable RSpec/MultipleExpectations
      # Use a family we know exists
      family = RubyLLM.models.all.first.family
      family_models = RubyLLM.models.by_family(family)

      expect(family_models).to be_a(described_class)
      expect(family_models.all).to all(have_attributes(family: family))
      expect(family_models.all).not_to be_empty
    end
  end

  describe '#save_models' do
    it 'saves models to the models.json file' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      temp_file = Tempfile.new(['models', '.json'])
      allow(described_class).to receive(:models_file).and_return(temp_file.path)

      models = RubyLLM.models
      models.save_models

      # Verify file was written with valid JSON
      saved_content = File.read(temp_file.path)
      expect { JSON.parse(saved_content) }.not_to raise_error

      # Verify model data was saved
      parsed_models = JSON.parse(saved_content)
      expect(parsed_models.size).to eq(models.all.size)

      temp_file.unlink
    end
  end
end
