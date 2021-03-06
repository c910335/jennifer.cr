module Jennifer
  module Adapter
    module RequestMethods
      # query ===========================

      def insert(obj : Model::Base)
        opts = obj.arguments_to_insert
        query = String.build do |s|
          s << "INSERT INTO " << obj.class.table_name << "("
          opts[:fields].join(", ", s)
          s << ") values (" << self.class.escape_string(opts[:fields].size) << ")"
        end
        exec parse_query(query, opts[:args]), opts[:args]
      end

      def update(obj : Model::Base)
        opts = obj.arguments_to_save
        return DB::ExecResult.new(0i64, -1i64) if opts[:args].empty?
        opts[:args] << obj.primary
        esc = self.class.escape_string(1)
        query = String.build do |s|
          s << "UPDATE " << obj.class.table_name << " SET "
          opts[:fields].map { |f| "#{f}= #{esc}" }.join(", ", s)
          s << " WHERE " << obj.class.primary_field_name << " = " << esc
        end
        exec(parse_query(query, opts[:args]), opts[:args])
      end

      def update(q, options : Hash)
        esc = self.class.escape_string(1)
        query = String.build do |s|
          s << "UPDATE " << q.table << " SET "
          options.map { |k, v| "#{k.to_s}= #{esc}" }.join(", ", s)
          s << "\n"
          s << q.body_section
        end
        args = [] of DBAny
        options.each do |k, v|
          args << v
        end
        args += q.select_args
        exec(parse_query(query, args), args)
      end

      def distinct(query : QueryBuilder::ModelQuery, column, table)
        str = String.build do |s|
          s << "SELECT DISTINCT " << table << "." << column << "\n"
          query.from_clause(s)
          s << query.body_section
        end
        args = query.select_args
        result = [] of DBAny
        query(parse_query(str, args), args) do |rs|
          rs.each do
            result << result_to_array(rs)[0]
          end
        end
        result
      end

      def pluck(query, fields : Array)
        result = [] of Array(DBAny)
        body = query.select_query(fields)
        args = query.select_args
        query(parse_query(body, args), args) do |rs|
          rs.each do
            result << result_to_array_by_names(rs, fields)
          end
        end
        result
      end

      def pluck(query, field)
        field = field.to_s
        result = [] of DBAny
        body = query.select_query([field])
        args = query.select_args
        fields = [field]
        query(parse_query(body, args), args) do |rs|
          rs.each do
            result << result_to_array_by_names(rs, fields)[0]
          end
        end
        result
      end

      def select(q)
        body = q.select_query
        args = q.select_args
        query(parse_query(body, args), args) { |rs| yield rs }
      end
    end
  end
end
