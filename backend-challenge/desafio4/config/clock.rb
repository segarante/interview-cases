require "clockwork"
require_relative "./boot"
require_relative "./environment"

module Clock
  include Clockwork

  SIMULATOR_INTERVAL = Integer(ENV.fetch("SIMULATOR_CYCLE_INTERVAL_SECONDS", "60"))
  ACTIVITY_INTERVAL  = Integer(ENV.fetch("ACTIVITY_TICK_INTERVAL_SECONDS", "5"))

  every(SIMULATOR_INTERVAL.seconds, "simulator.tick") do
    ImportJob.perform_async
  end

  every(ACTIVITY_INTERVAL.seconds, "activity.tick") do
    ActivitySimulatorJob.perform_async
  end
end
