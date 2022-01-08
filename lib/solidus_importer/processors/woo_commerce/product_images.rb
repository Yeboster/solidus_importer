# frozen_string_literal: true

module SolidusImporter
  module Processors
    module WooCommerce
      class ProductImages < ::SolidusImporter::Processors::Base
        IMAGE_SRC_KEY = 'Featured Image'

        def call(context)
          @data = context.fetch(:data)
          return unless product_image?

          product = context.fetch(:product)
          process_images(product)
        end

        private

        def prepare_image
          attachment = URI.parse(@data[IMAGE_SRC_KEY]).open
          Spree::Image.new(attachment: attachment, alt: @data['Featured Image Alternative Text'], position: 0)
        end

        def process_images(product)
          product.images << prepare_image
        end

        def product_image?
          @product_image ||= @data[IMAGE_SRC_KEY].present?
        end
      end
    end
  end
end
