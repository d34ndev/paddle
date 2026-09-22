module Paddle
  class Simulation < Object
    class << self
      def list(**params)
        response = Client.get_request("simulations", params: params)
        Collection.from_response(response, type: Simulation)
      end

      def create(setting_id:, name:, type:, **params)
        attrs = { notification_setting_id: setting_id, name: name, type: type }
        response = Client.post_request("simulations", body: attrs.merge(params))
        Simulation.new(response.body["data"])
      end

      def retrieve(id:)
        response = Client.get_request("simulations/#{id}")
        Simulation.new(response.body["data"])
      end

      def update(id:, **params)
        response = Client.patch_request("simulations/#{id}", body: params)
        Simulation.new(response.body["data"])
      end

      def runs(id:, **params)
        response = Client.get_request("simulations/#{id}/runs", params: params)
        Collection.from_response(response, type: SimulationRun)
      end
    end
  end
end
