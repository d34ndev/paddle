require "test_helper"

class SimulationTest < Minitest::Test
  def test_simulation_runs_with_params
    runs = Paddle::Simulation.runs(id: "ntfsim_01j82d983j814ypzx7m1fw2jpz", per_page: 1, include: "events")

    assert_equal Paddle::Collection, runs.class
    assert_equal Paddle::SimulationRun, runs.first.class
    assert_equal "ntfsimrun_01j82h13n87yq4fvz2rmsvhknc", runs.first.id
  end

  def test_simulation_run_events_with_params
    events = Paddle::SimulationRun.events(
      simulation_id: "ntfsim_01j82d983j814ypzx7m1fw2jpz",
      id: "ntfsimrun_01j82h13n87yq4fvz2rmsvhknc",
      per_page: 1
    )

    assert_equal Paddle::Collection, events.class
    assert_equal Paddle::SimulationRunEvent, events.first.class
    assert_equal "subscription.created", events.first.event_type
  end
end
