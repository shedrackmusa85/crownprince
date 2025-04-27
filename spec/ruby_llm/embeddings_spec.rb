# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Embedding do
  include_context 'with configured RubyLLM'

  let(:test_text) { "Ruby is a programmer's best friend" }
  let(:test_texts) { %w[Ruby Python JavaScript] }

  embedding_models = %w[text-embedding-004 text-embedding-3-small].freeze

  describe 'basic functionality' do
    embedding_models.each do |model|
      provider = RubyLLM::Models.provider_for(model).slug
      it "#{provider}/#{model} can handle a single text" do # rubocop:disable RSpec/MultipleExpectations
        embedding = RubyLLM.embed(test_text, model: model)
        expect(embedding.vectors).to be_an(Array)
        expect(embedding.vectors.first).to be_a(Float)
        expect(embedding.model).to eq(model)
        expect(embedding.input_tokens).to be >= 0
      end

      it "#{provider}/#{model} can handle multiple texts" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
        embeddings = RubyLLM.embed(test_texts, model: model)
        expect(embeddings.vectors).to be_an(Array)
        expect(embeddings.vectors.size).to eq(3)
        expect(embeddings.vectors.first).to be_an(Array)
        expect(embeddings.model).to eq(model)
        expect(embeddings.input_tokens).to be >= 0
      end
    end
  end
end
