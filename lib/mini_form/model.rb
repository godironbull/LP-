
require_relative "database"

class Model
  SQL_TYPES = {
    string: "TEXT",
    email: "TEXT",
    integer: "INTEGER"
  }.freeze

  attr_reader :id

  def self.fields
    @fields ||= []
  end

  def self.field(name, type)
    raise ArgumentError, "Tipo inválido" unless SQL_TYPES.key?(type)
    raise ArgumentError, "Nome inválido" unless name.to_s.match?(/\A[a-zA-Z_]\w*\z/)
    raise ArgumentError, "Campo duplicado" if fields.any? { |f| f[:name] == name }

    fields << { name: name, type: type }
    attr_accessor name
  end

  def initialize(attributes = {})
    attributes.each do |name, value|
      setter = "#{name}="
      public_send(setter, value) if respond_to?(setter)
    end
  end

  def self.table_name
    "#{name.downcase}s"
  end

  def self.create_table!
    definitions = ["id INTEGER PRIMARY KEY AUTOINCREMENT"]

    fields.each do |field|
      definitions << "#{field[:name]} #{SQL_TYPES.fetch(field[:type])}"
    end

    sql = "CREATE TABLE IF NOT EXISTS #{table_name} (#{definitions.join(', ')})"
    Database.connection.execute(sql)
  end

  # Cria um registro novo e guarda seu ID.
  def save
    self.class.create_table!

    if id
      attributes = self.class.fields.to_h do |field|
        name = field[:name]
        [name, public_send(name)]
      end

      return update(attributes)
    end

    columns = self.class.fields.map { |field| field[:name] }
    values = columns.map { |column| public_send(column) }
    placeholders = Array.new(columns.length, "?").join(", ")

    sql = <<~SQL
      INSERT INTO #{self.class.table_name}
      (#{columns.join(", ")})
      VALUES (#{placeholders})
    SQL

    db = Database.connection
    db.execute(sql, values)
    @id = db.last_insert_row_id

    self
  end

  # Busca um registro pelo ID.
  # Retorna um objeto ou nil se não existir.
  def self.find(id)
    create_table!

    columns = fields.map { |field| field[:name] }
    selected_columns = (["id"] + columns).join(", ")

    sql = "SELECT #{selected_columns} FROM #{table_name} WHERE id = ? LIMIT 1"
    row = Database.connection.get_first_row(sql, [id])

    return nil unless row

    attributes = columns.zip(row.drop(1)).to_h
    object = new(attributes)
    object.instance_variable_set(:@id, row[0])

    object
  end

  # Atualiza os atributos informados.
  def update(attributes)
    raise ArgumentError, "Salve o objeto antes de atualizá-lo" unless id

    attributes = attributes.transform_keys(&:to_sym)
    allowed_columns = self.class.fields.map { |field| field[:name] }
    unknown = attributes.keys - allowed_columns

    unless unknown.empty?
      raise ArgumentError, "Campos desconhecidos: #{unknown.join(', ')}"
    end

    return self if attributes.empty?

    assignments = attributes.keys.map { |name| "#{name} = ?" }.join(", ")
    values = attributes.values

    sql = "UPDATE #{self.class.table_name} SET #{assignments} WHERE id = ?"

    Database.connection.execute(sql, values + [id])

    attributes.each do |name, value|
      public_send("#{name}=", value)
    end

    self
  end

  # Exclui o registro correspondente ao ID do objeto.
  # Retorna true se excluiu; false se o objeto não estava salvo.
  def delete
    return false unless id

    db = Database.connection
    db.execute(
      "DELETE FROM #{self.class.table_name} WHERE id = ?",
      [id]
    )

    deleted = db.changes.positive?
    @id = nil if deleted

    deleted
  end

  # Retorna todos os registros como objetos Ruby.
  def self.all
    create_table!

    columns = fields.map { |field| field[:name] }
    selected_columns = (["id"] + columns).join(", ")

    sql = "SELECT #{selected_columns} FROM #{table_name}"

    Database.connection.execute(sql).map do |row|
      attributes = columns.zip(row.drop(1)).to_h
      object = new(attributes)
      object.instance_variable_set(:@id, row[0])
      object
    end
  end
end
