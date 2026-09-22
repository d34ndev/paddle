module Paddle
  class Collection
    include Enumerable

    attr_reader :data, :total, :per_page, :next_url

    def self.from_response(response, type:)
      body = response.body

      data = body["data"].map { |attrs| type.new(attrs) }
      pagination = body.dig("meta", "pagination")

      if pagination
        new(
          data: data,
          total: pagination["estimated_total"],
          per_page: pagination["per_page"],
          has_more: pagination["has_more"],
          next_url: pagination["next"],
          type: type
        )
      else
        new(data: data, total: data.count)
      end
    end

    def initialize(data:, total:, per_page: nil, has_more: false, next_url: nil, type: nil)
      @data = data
      @total = total
      @per_page = per_page
      @has_more = has_more
      @next_url = next_url
      @type = type
    end

    def has_more?
      @has_more == true
    end

    # Paddle returns a next URL even on the last page, so has_more is checked first
    def next_page
      return unless has_more? && next_url && @type

      # Only the path and query are used, so requests always go to the configured API host
      response = Client.get_request(URI(next_url).request_uri.delete_prefix("/"))
      Collection.from_response(response, type: @type)
    end

    def auto_paging_each(&block)
      return enum_for(:auto_paging_each) unless block_given?

      page = self
      while page
        page.each(&block)
        page = page.next_page
      end
    end

    def each(&block)
      data.each(&block)
    end

    def first
      data.first
    end

    def last
      data.last
    end
  end
end
