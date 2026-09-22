module Paddle
  class SimulationRun < Object
    class << self
      def create(simulation_id:, **params)
        response = Client.post_request("simulations/#{simulation_id}/runs", body: {})
        SimulationRun.new(response.body["data"])
      end

      def retrieve(simulation_id:, id:)
        response = Client.get_request("simulations/#{simulation_id}/runs/#{id}")
        SimulationRun.new(response.body["data"])
      end

      def events(simulation_id:, id:, **params)
        response = Client.get_request("simulations/#{simulation_id}/runs/#{id}/events", params: params)
        Collection.from_response(response, type: SimulationRunEvent)
      end
    end
  end
end
