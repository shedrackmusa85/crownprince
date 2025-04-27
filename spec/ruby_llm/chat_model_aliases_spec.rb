# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Chat do
  include_context 'with configured RubyLLM'

  it 'finds models by alias name' do # rubocop:disable RSpec/MultipleExpectations
    # Core test - can we find a model using just its alias?
    chat = RubyLLM.chat(model: 'claude-3-5-sonnet')
    expect(chat.model.id).to eq('claude-3-5-sonnet-20241022')
    expect(chat.model.provider).to eq('anthropic')
  end

  it 'still supports exact model IDs' do # rubocop:disable RSpec/MultipleExpectations
    # Backward compatibility check
    chat = RubyLLM.chat(model: 'claude-3-5-sonnet-20241022')
    expect(chat.model.id).to eq('claude-3-5-sonnet-20241022')
    expect(chat.model.provider).to eq('anthropic')
  end

  it 'finds models by alias and provider' do # rubocop:disable RSpec/MultipleExpectations
    chat = RubyLLM.chat(model: 'claude-3-5-haiku', provider: :bedrock)
    expect(chat.model.id).to eq('anthropic.claude-3-5-haiku-20241022-v1:0')
    expect(chat.model.provider).to eq('bedrock')
  end
end
