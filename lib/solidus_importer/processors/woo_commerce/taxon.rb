# frozen_string_literal: true

module SolidusImporter
  module Processors
    module WooCommerce
      class Taxon < ::SolidusImporter::Processors::Base
        attr_accessor :product, :taxonomy, :brand_taxonomy

        def call(context)
          @data = context.fetch(:data)

          self.product = context.fetch(:product)
          self.taxonomy = options[:root_taxonomy]
          self.brand_taxonomy = options[:brand_taxonomy]

          process_taxons
        end

        private

        def options
          @options ||= {
            root_taxonomy: Spree::Taxonomy.find_or_create_by(name: 'Categories'),
            tags_taxonomy: Spree::Taxonomy.find_or_create_by(name: 'Tags'),
            brand_taxonomy: Spree::Taxonomy.find_or_create_by(name: 'Brand')
          }
        end

        def process_taxons
          return unless taxon_hierarchy

          if product_brand
            add_taxon_to_prod brand_taxonomy.root.children.find_or_create_by(name: product_brand,
              taxonomy_id: brand_taxonomy.id)
          end

          taxon_hierarchy.split('|').map do |taxon|
            last_taxon = taxonomy.root
            taxon.split('>').each do |sub_taxon|
              last_taxon = last_taxon.children.find_or_create_by(name: sub_taxon, taxonomy_id: taxonomy.id)
            end

            add_taxon_to_prod(last_taxon)
          end
        end

        def add_taxon_to_prod(taxon)
          product.taxons << taxon unless product.taxons.include?(taxon)
        end

        def product_brand
          splitted = @data['Product Name']&.split(' – ')
          return unless splitted&.size&.> 1

          splitted.first.strip.capitalize
        end

        def taxon_hierarchy
          @data['Category'].presence
        end
      end
    end
  end
end
