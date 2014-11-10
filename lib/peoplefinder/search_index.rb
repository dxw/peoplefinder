require 'peoplefinder'

class Peoplefinder::SearchIndex
  def import(people)
    people.each do |person|
      index(person)
    end
  end

  def delete(person)
    ActiveRecord::Base.connection.delete(
      'DELETE from search_index where person_id=$1',
      'delete person',
      [[nil, person.id]]
    )
  end

  def index(person)
    ImportOne.new(person).call
  end

  def search(query, limit: 100)
    rows = ActiveRecord::Base.connection.select_rows(%q{
      SELECT person_id
      FROM search_index
      WHERE document @@ plainto_tsquery('english', $1)
      ORDER BY ts_rank(document, plainto_tsquery('english', $1)) DESC
      LIMIT $2
      },
      'text search',
      [[nil, query], [nil, limit]]
    )

    people_ids = rows.map { |row| row.first.to_i }
    load_people_in_order(people_ids)
  end

  def load_people_in_order(people_ids)
    people = Peoplefinder::Person.find(people_ids)
    people_by_id = Hash[people.map { |p| [p.id, p] }]
    people_ids.map { |id| people_by_id[id] }
  end

  class ImportOne
    attr_reader :person, :index_language

    def initialize(person, index_language = 'english')
      @person = person
      @index_language = index_language
    end

    def call
      if search_record_exists?
        do_update
      else
        do_insert
      end
    end

    def search_record_exists?
      ActiveRecord::Base.connection.select_one(
        'select person_id from search_index where person_id=$1',
        nil,
        [[nil, person.id]]
      )
    end

    def do_update
      binds = [person.id, person_name] + document_sql.binds
      ActiveRecord::Base.connection.update(
        'UPDATE search_index ' \
        'SET ' \
        'name = $2, ' \
        "document = #{document_sql.sql(2)} " \
        'WHERE person_id = $1',
        'update search index',
        binds.map { |b| [nil, b] }
      )
    end

    def do_insert
      ActiveRecord::Base.connection.insert(
        'INSERT INTO search_index (person_id, name, document) ' \
        'VALUES ' \
        "($1, $2, #{document_sql.sql(2)})",
        nil, nil, nil, nil,
        ([person.id, person_name] + document_sql.binds).map { |b| [nil, b] }
      )
    end

    def person_name
      "#{person.given_name} #{person.surname}"
    end

    def indexable_data
      [
        [person_name, 'A'],
        [person.location],
        [person.description],
        [person.role_and_group],
        [person.community_name],
        [person.tags]
      ].map { |data, weight| BoundSql.for_data(index_language, data, weight) }
    end

    def document_sql
      BoundSql.concatenate(indexable_data)
    end

    class BoundSql
      attr_reader :binds

      def initialize(sql, binds)
        @sql = sql
        @binds = binds
      end

      def self.for_data(index_language, data, weight = 'D')
        BoundSql.new(
          'setweight(to_tsvector($1, $2), $3)',
          [index_language, data || '', weight || 'D']
        )
      end

      def self.concatenate(bound_sql_list, join_sql = '||')
        bound_sql_list.inject { |memo, elem| memo.join(elem, join_sql) }
      end

      def sql(bind_number_offset = 0)
        @sql.gsub(/\$([0-9]+)/) do |_|
          '$' + (Regexp.last_match[1].to_i + bind_number_offset).to_s
        end
      end

      def join(other, join_sql = '||')
        BoundSql.new(
          self.sql + join_sql + other.sql(self.binds.size),
          self.binds + other.binds
        )
      end
    end
  end
end
