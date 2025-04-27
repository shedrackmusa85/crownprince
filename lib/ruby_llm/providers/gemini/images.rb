# frozen_string_literal: true

module RubyLLM
  module Providers
    module Gemini
      # Image generation methods for the Gemini API implementation
      module Images
        def images_url
          "models/#{@model}:predict"
        end

        def render_image_payload(prompt, model:, size:) # rubocop:disable Metrics/MethodLength
          RubyLLM.logger.debug "Ignoring size #{size}. Gemini does not support image size customization."
          @model = model
          {
            instances: [
              {
                prompt: prompt
              }
            ],
            parameters: {
              sampleCount: 1
            }
          }
        end

        def parse_image_response(response) # rubocop:disable Metrics/MethodLength
          data = response.body
          image_data = data['predictions']&.first

          unless image_data&.key?('bytesBase64Encoded')
            raise Error, 'Unexpected response format from Gemini image generation API'
          end

          # Extract mime type and base64 data
          mime_type = image_data['mimeType'] || 'image/png'
          base64_data = image_data['bytesBase64Encoded']

          Image.new(
            data: base64_data,
            mime_type: mime_type
          )
        end
      end
    end
  end
end
