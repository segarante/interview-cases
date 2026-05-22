# Limpa locks remanescentes do SingleRun no boot da aplicação.
# Evita locks órfãos travando jobs do Sidekiq após um shutdown sujo
# (ex.: kill -9, container morto durante a execução).
#
# Roda apenas no processo do Rails server para evitar corrida com
# jobs já em execução nos containers de sidekiq/clockwork.
Rails.application.config.after_initialize do
  next unless defined?(Rails::Server)

  pattern = "#{SingleRun::KEY_PREFIX}:*"
  cleared = Sidekiq.redis do |r|
    keys = r.keys(pattern)
    r.del(*keys) unless keys.empty?
    keys.size
  end

  Rails.logger.info("[job_locks] cleared #{cleared} stale lock(s) on boot")
rescue => e
  Rails.logger.warn("[job_locks] failed to clear locks: #{e.class}: #{e.message}")
end
