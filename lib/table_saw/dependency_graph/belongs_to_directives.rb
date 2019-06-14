# frozen_string_literal: true

module TableSaw
  module DependencyGraph
    class BelongsToDirectives
      attr_reader :context, :directive

      def initialize(context, directive)
        @context = context
        @directive = directive
      end

      def call
        associations.map do |from_column, to_table|
          TableSaw::DependencyGraph::AddDirective.new(to_table, ids: ids[from_column].to_a, partial: directive.partial?)
        end
      end

      private

      def associations
        context.belongs_to.fetch(directive.table_name, {})
      end

      def ids
        @ids ||= query_result.each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |row, memo|
          associations.each_key { |key| memo[key].add row[key] unless row[key].nil? }
        end
      end

      def query_result
        return [] unless directive.selectable?

        context.perform_query(
          format('select %{columns} from %{table_name} where id in (%{ids})',
                 columns: associations.keys.join(','), table_name: directive.table_name, ids: directive.ids.join(','))
        )
      end
    end
  end
end
