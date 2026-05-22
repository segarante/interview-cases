# Garante que apenas uma instância do job esteja em execução por vez.
# Grava uma chave no Redis no início e remove no final (sucesso ou falha).
# Se a chave já existir quando o job começa, ele apenas registra e sai —
# evita acúmulo de execuções concorrentes quando um ciclo demora mais
# do que o intervalo do clock.
module SingleRun
  KEY_PREFIX = "desafio4:job_lock".freeze

  def self.included(base)
    base.prepend(Wrapper)
  end

  module Wrapper
    def perform(*args)
      key = "#{SingleRun::KEY_PREFIX}:#{self.class.name}"
      acquired = Sidekiq.redis { |r| r.set(key, Process.pid.to_s, nx: true) }

      unless acquired
        BroadcastLogger.new.warn("[#{self.class.name}] já em execução, descartando tick")
        return
      end

      begin
        super
      ensure
        Sidekiq.redis { |r| r.del(key) }
      end
    end
  end
end
