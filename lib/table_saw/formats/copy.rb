# frozen_string_literal: true

module TableSaw
  module Formats
    class Copy < TableSaw::Formats::Base
      def initialize(table_name, options: {})
        super
        @columns = TableSaw.schema_cache.columns_hash(table_name).filter do |name, col|
          !col.virtual?
        end.each_key.to_a
      end

      def header
        "COPY #{table_name} (#{quoted_columns}) FROM STDIN;"
      end

      def footer
        ['\.', "\n"]
      end

      def dump_row(row)
        row
      end

      private

      def quoted_columns
        @columns
          .map { |name| TableSaw.connection.quote_column_name(name) }
          .join(', ')
      end
    end
  end
end
