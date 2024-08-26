# frozen_string_literal: true

module TableSaw
  module DependencyGraph
    class DumpTable
      attr_reader :manifest, :name, :partial, :ids

      def initialize(manifest:, name:, partial: true)
        @manifest = manifest
        @name = name
        @partial = partial
        @ids = Set.new
        @columns = TableSaw.schema_cache.columns_hash(name).filter do |name, col|
          !col.virtual?
        end.each_key.to_a
      end

      def copy_statement
        if partial
          format "select #{quoted_columns} from %{name} where %{clause}",
                 name:, clause: TableSaw::Queries::SerializeSqlInClause.new(name, primary_key, ids.to_a).call

        else
          "select #{quoted_columns} from #{name}"
        end
      end

      def fetch_associations(directive)
        directive.ids = directive.ids - ids.to_a
        ids.merge(directive.ids)
        fetch_belongs_to(directive) + fetch_has_many(directive)
      end

      private

      def quoted_columns
        @columns
          .map { |name| TableSaw.connection.quote_column_name(name) }
          .join(', ')
      end

      def fetch_belongs_to(directive)
        TableSaw::DependencyGraph::BelongsToDirectives.new(manifest, directive).call
      end

      def fetch_has_many(directive)
        TableSaw::DependencyGraph::HasManyDirectives.new(manifest, directive).call
      end

      def primary_key
        TableSaw.schema_cache.primary_keys(name)
      end
    end
  end
end
