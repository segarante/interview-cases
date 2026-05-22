require Rails.root.join("fixtures/policy_fixture_generator")

class ImportJob
  include Sidekiq::Job
  include SingleRun

  MIN_POLICIES_PER_CYCLE = Integer(ENV.fetch("SIMULATOR_MIN_POLICIES_PER_CYCLE", "2"))
  MAX_POLICIES_PER_CYCLE = Integer(ENV.fetch("SIMULATOR_MAX_POLICIES_PER_CYCLE", "30"))
  INITIAL_SEED_COUNT     = Integer(ENV.fetch("SIMULATOR_INITIAL_SEED_COUNT", "100"))

  def perform
    @logger = BroadcastLogger.new

    pre_import
    run_import
  end

  private

  # === Parte 1: SIMULAÇÃO =====================================================
  # Gera dados fictícios para que haja algo para importar. Em produção essa
  # etapa não existiria — os dados viriam da seguradora externa.
  def pre_import
    seed_fixtures_if_empty

    count = rand(MIN_POLICIES_PER_CYCLE..MAX_POLICIES_PER_CYCLE)
    @logger.info("[Simulação] gerando #{count} apólices fictícias como se viessem da seguradora")
    PolicyFixtureGenerator.new.generate(count)
    @logger.info("[Simulação] geração concluída, #{count} apólices disponíveis para importar")
  end

  def seed_fixtures_if_empty
    return if fixture_files.any?

    @logger.info("[Simulação] nenhum fixture encontrado, semeando #{INITIAL_SEED_COUNT} apólices iniciais")
    PolicyFixtureGenerator.new.generate(INITIAL_SEED_COUNT)
    @logger.info("[Simulação] seed inicial concluída")
  end

  # === Parte 2: IMPORTAÇÃO ====================================================
  # Dispara o pipeline real de importação para um único policy_holder por ciclo
  # — sempre o primeiro em ordem alfabética entre os fixtures existentes.
  def run_import
    policy_holder = pick_policy_holder
    return @logger.warn("[Import] nenhum policy_holder disponível, pulando ciclo") unless policy_holder

    Import.new(policy_holder, logger: @logger).call
  end

  def pick_policy_holder
    file = fixture_files.sort.first
    File.basename(file, ".json") if file
  end

  def fixture_files
    Dir.glob(Rails.root.join("fixtures/data/*.json"))
  end
end
