
require_relative "lib/mini_form/model"

class Funcionario < Model
  field :nome, :string
  field :sobrenome, :string
  field :cpf, :string
  field :email, :email
  field :telefone, :string
  field :cargo, :string
  field :departamento, :string
  field :salario, :integer
  field :idade, :integer
  field :tempo_empresa, :integer
  field :cidade, :string
  field :estado, :string
end

# Criar funcionário
funcionario = Funcionario.new(
  nome: "Carlos",
  sobrenome: "Silva",
  cpf: "12345678900",
  email: "carlos@example.com",
  telefone: "44999990000",
  cargo: "Desenvolvedor",
  departamento: "Tecnologia",
  salario: 5000,
  idade: 30,
  tempo_empresa: 3,
  cidade: "Campo Mourão",
  estado: "PR"
)

# Salvar no banco
funcionario.save
funcionario.save
puts "Funcionário criado: ID #{funcionario.id}"

# Consultar
encontrado = Funcionario.find(funcionario.id)
puts "Encontrado: #{encontrado.nome} #{encontrado.sobrenome}"

# Atualizar
encontrado.update(
  cargo: "Desenvolvedor Sênior",
  salario: 7000
)

atualizado = Funcionario.find(funcionario.id)
puts "Novo cargo: #{atualizado.cargo}"
puts "Novo salário: #{atualizado.salario}"

# Listar todos
puts "\nFuncionários cadastrados:"
Funcionario.all.each do |f|
  puts "#{f.id} - #{f.nome} - #{f.cargo} - #{f.salario}"
end

# Excluir
if atualizado.delete
  puts "\nFuncionário excluído com sucesso!"
end
