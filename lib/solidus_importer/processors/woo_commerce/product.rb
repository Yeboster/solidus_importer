# frozen_string_literal: true

module SolidusImporter
  module Processors
    module WooCommerce
      class Product < ::SolidusImporter::Processors::Base
        PRODUCT_SKU_KEY = 'Product SKU'
        PRODUCT_SLUG_KEY = 'Slug'

        def call(context)
          @data = context.fetch(:data)
          check_data
          context.merge!(product: process_product)
        end

        def options
          @options ||= {
            available_on: Date.current.yesterday,
            not_available: nil,
            price: 0,
            shipping_category: Spree::ShippingCategory.find_by(name: 'Default') || Spree::ShippingCategory.first
          }
        end

        private

        def product_name
          @data['Product Name']
        end

        def product_sku
          @data[PRODUCT_SKU_KEY]
        end

        def product_slug
          @data[PRODUCT_SLUG_KEY]
        end

        def product_price
          @data['Price']&.sub(',', '.')&.to_f
        end

        def tax_category
          default_pct = 22
          tax_pct = @data['Tax Class']&.to_i || default_pct
          tax_category = Spree::TaxCategory.find_or_create_by(name: tax_pct).tap do |tax|
            tax.tax_code = tax_pct
            tax.is_default = tax_pct == default_pct
          end

          tax_category.tax_rates.find_or_create_by(name: tax_pct) do |rate|
            rate.amount = tax_pct * 0.01
            rate.zone = Spree::Zone.first
            rate.calculator = Spree::Calculator.first
          end

          tax_category
        end

        def product_published_at
          day, month, year = @data['Product Published']&.split('/')&.map(&:to_i)
          return options[:available_on] unless day && month && year

          Date.new year, month, day
        end

        def check_data
          raise SolidusImporter::Exception, "Missing required key: '#{PRODUCT_SKU_KEY}'" if product_sku&.blank?
          raise SolidusImporter::Exception, "Missing required key: '#{PRODUCT_SLUG_KEY}'" if product_slug&.blank?
        end

        def prepare_product
          Spree::Product.find_or_initialize_by(slug: product_sku)
        end

        def process_product
          prepare_product.tap do |product|
            product.sku = product_sku
            product.slug = product_slug
            product.price = product_price
            product.available_on = available? ? product_published_at : options[:not_available]
            product.shipping_category = options[:shipping_category]

            # Apply the row attributes
            product.name = product_name
            product.description = @data['Excerpt']
            product.tax_category = tax_category
            product.meta_title = product_name

            # Add product properties
            product.set_property('woocommerce_id', @data['Product ID'])

            # Save the product
            product.save!
          end
        end

        def available?
          @data['Product Status'] == 'Publish'
        end
      end
    end
  end
end
