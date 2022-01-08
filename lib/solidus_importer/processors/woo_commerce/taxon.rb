# frozen_string_literal: true

module SolidusImporter
  module Processors
    module WooCommerce
      class Taxon < ::SolidusImporter::Processors::Base
        attr_accessor :product, :taxonomy

        def call(context)
          @data = context.fetch(:data)

          self.product = context.fetch(:product)
          self.taxonomy = options[:root_taxonomy]

          process_taxons
        end

        private

        def options
          @options ||= {
            root_taxonomy: Spree::Taxonomy.find_or_create_by(name: 'Categories'),
            tags_taxonomy: Spree::Taxonomy.find_or_create_by(name: 'Tags')
          }
        end

        def process_taxons
          return unless taxon_hierarchy

          taxon_hierarchy.split('|').map do |taxon|
            last_taxon = taxonomy.root
            taxon.split('>').each do |taxon|
              last_taxon = last_taxon.children.find_or_create_by(name: taxon, taxonomy_id: taxonomy.id)
            end

            add_taxon(last_taxon)
          end
        end

        def add_taxon(taxon)
          product.taxons << taxon unless product.taxons.include?(taxon)
        end


        def prepare_taxon(name, parent_taxon)
          Spree::Taxon.find_or_initialize_by(
            name: name,
            taxonomy_id: taxonomy.id
          )
        end

        def taxon_hierarchy
          @data['Category'].presence
        end
      end
    end
  end
end
