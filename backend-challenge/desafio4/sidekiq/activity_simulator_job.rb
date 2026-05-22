# Emite UM evento aleatório de "atividade" da aplicação, para gerar ruído
# de logs decorativo na tela. Enfileirado periodicamente pelo clock
# (config/clock.rb).
class ActivitySimulatorJob
  include Sidekiq::Job
  include SingleRun

  FUNNY_INSURERS = [
    "Divisor Seguros",
    "Boné Seguros",
    "Aeroporto Seguro",
    "Perde Seguros",
    "Olde Seguros",
    "Boreal Seguradora",
    "UnfairPhone Seguros",
    "Hard Seguros",
    "Vida Brasileira Seguros",
    "Impotencial Seguros",
    "Prision Seguros",
    "Separado Seguros"
  ].freeze

  EVENTS = [
    { level: :info,  message: -> { "Nova apolice criada" } },
    { level: :info,  message: -> { "Nova solicitacao recebida" } },
    { level: :info,  message: -> { "Novo endosso criado" } },
    { level: :info,  message: -> { "Nova cotacao recebida da seguradora #{FUNNY_INSURERS.sample}" } },
    { level: :error, message: -> { "Erro na cotacao com a seguradora #{FUNNY_INSURERS.sample}" } },
    { level: :error, message: -> { "Erro ao criar endosso" } },
    { level: :info,  message: -> { "Pagamento de premio confirmado para apolice ##{random_policy_number}" } },
    { level: :warn,  message: -> { "Apolice ##{random_policy_number} vence em #{rand(1..30)} dias" } },
    { level: :info,  message: -> { "Renovacao automatica processada (#{FUNNY_INSURERS.sample})" } },
    { level: :info,  message: -> { "Sinistro aberto para apolice ##{random_policy_number}" } },
    { level: :warn,  message: -> { "Falha de comunicacao com #{FUNNY_INSURERS.sample}, tentando reconectar" } },
    { level: :info,  message: -> { "Webhook recebido de #{FUNNY_INSURERS.sample}" } },
    { level: :info,  message: -> { "Documento anexado a apolice ##{random_policy_number}" } },
    { level: :info,  message: -> { "Reanalise de risco solicitada para apolice ##{random_policy_number}" } },
    { level: :error, message: -> { "Falha ao gerar boleto da apolice ##{random_policy_number}" } },
    { level: :info,  message: -> { "Email enviado ao segurado da apolice ##{random_policy_number}" } },
    { level: :warn,  message: -> { "Limite de cotacoes diarias proximo do teto (#{FUNNY_INSURERS.sample})" } },
    { level: :info,  message: -> { "Auditoria diaria iniciada" } },
    { level: :error, message: -> { "Timeout consultando #{FUNNY_INSURERS.sample}" } }
  ].freeze

  def perform
    event = EVENTS.sample
    logger = BroadcastLogger.new
    logger.public_send(event[:level], "[Activity] #{instance_exec(&event[:message])}")
  end

  private

  def random_policy_number
    format("%09d", rand(1..999_999))
  end
end
