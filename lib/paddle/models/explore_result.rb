module Paddle
  # The result of an Explore query. Pages are made up of series (one per combination of dimension
  # values), and the next page is requested by POSTing the same query to the next URL
  class ExploreResult < Object
    def self.from_response(response, query:)
      new(response.body["data"], query: query, pagination: response.body.dig("meta", "pagination"))
    end

    def initialize(attributes, query: {}, pagination: nil)
      super(attributes)
      @query = query
      @pagination = pagination || {}
    end

    def per_page
      @pagination["per_page"]
    end

    def total
      @pagination["estimated_total"]
    end

    def next_url
      @pagination["next"]
    end

    def has_more?
      @pagination["has_more"] == true
    end

    def next_page
      return unless has_more? && next_url

      # Only the path and query are used, so requests always go to the configured API host
      response = Client.post_request(URI(next_url).request_uri.delete_prefix("/"), body: @query)
      ExploreResult.from_response(response, query: @query)
    end

    # Yields each series across all pages
    def auto_paging_each(&block)
      return enum_for(:auto_paging_each) unless block_given?

      page = self
      while page
        page.series.each(&block)
        page = page.next_page
      end
    end
  end
end
