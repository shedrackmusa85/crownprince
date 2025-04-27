# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

def save_and_verify_image(image) # rubocop:disable Metrics/MethodLength
  # Create a temp file to save to
  temp_file = Tempfile.new(['image', '.png'])
  temp_path = temp_file.path
  temp_file.close

  begin
    saved_path = image.save(temp_path)
    expect(saved_path).to eq(temp_path)
    expect(File.exist?(temp_path)).to be true

    file_size = File.size(temp_path)
    expect(file_size).to be > 1000 # Any real image should be larger than 1KB
  ensure
    # Clean up
    File.delete(temp_path)
  end
end

RSpec.describe RubyLLM::Image do
  include_context 'with configured RubyLLM'

  describe 'basic functionality' do
    it 'openai/dall-e-3 can paint images' do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
      image = RubyLLM.paint('a siamese cat', model: 'dall-e-3')

      expect(image.base64?).to be(false)
      expect(image.url).to start_with('https://')
      expect(image.mime_type).to include('image')
      expect(image.revised_prompt).to include('cat')

      save_and_verify_image image
    end

    it 'openai/dall-e-3 supports custom sizes' do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
      image = RubyLLM.paint('a siamese cat', size: '1792x1024', model: 'dall-e-3')

      expect(image.base64?).to be(false)
      expect(image.url).to start_with('https://')
      expect(image.mime_type).to include('image')
      expect(image.revised_prompt).to include('cat')

      save_and_verify_image image
    end

    it 'gemini/imagen-3.0-generate-002 can paint images' do # rubocop:disable RSpec/MultipleExpectations
      image = RubyLLM.paint('a siamese cat', model: 'imagen-3.0-generate-002')

      expect(image.base64?).to be(true)
      expect(image.data).to be_present
      expect(image.mime_type).to include('image')

      save_and_verify_image image
    end

    it 'validates model existence' do
      expect do
        RubyLLM.paint('a cat', model: 'invalid-model')
      end.to raise_error(RubyLLM::ModelNotFoundError)
    end
  end
end
