class ErrorTest < Minitest::Test
  def test_bad_request_error
    error = Paddle::ErrorFactory.create(
      { "error" => { "code" => 123, "detail" => "Paddle error message" } },
      400
    )

    assert_equal "Error 400: Paddle error message '123'", error.message
  end

  def test_authentication_missing_error
    error = Paddle::ErrorFactory.create(
      { "error": {} },
      401
    )

    assert_equal "Error 401: You did not supply valid authentication credentials.", error.message
  end

  def test_paddle_error_generator_message
    error = Paddle::ErrorGenerator.new({ "error" => { "code" => 123, "detail" => "Paddle error message" } }, 409)

    assert_equal "Paddle error message", error.paddle_error_message
  end

  def test_paddle_error_message
    error = Paddle::Error.new("Connection failed")

    assert_equal "Connection failed", error.message
  end

  def test_bad_request_error_with_field_errors
    error = Paddle::ErrorFactory.create(
      {
        "error" => {
          "type" => "request_error",
          "code" => "bad_request",
          "detail" => "Invalid request.",
          "documentation_url" => "https://developer.paddle.com/v1/errors/shared/bad_request",
          "errors" => [
            { "field" => "trial_period", "message" => "Must validate one and only one schema (oneOf)" },
            { "field" => "trial_period.frequency", "message" => "Invalid type. Expected: integer, given: string" }
          ]
        },
        "meta" => { "request_id" => "e385967f-4298-4240-a971-f988209b32ca" }
      },
      400
    )

    expected_message = "Error 400: Invalid request. 'bad_request'\n" \
                      "Field errors:\n" \
                      "  - trial_period: Must validate one and only one schema (oneOf)\n" \
                      "  - trial_period.frequency: Invalid type. Expected: integer, given: string\n" \
                      "Documentation: https://developer.paddle.com/v1/errors/shared/bad_request\n" \
                      "Request ID: e385967f-4298-4240-a971-f988209b32ca"

    assert_equal expected_message, error.message
    assert_equal 2, error.paddle_errors.length
    assert_equal "https://developer.paddle.com/v1/errors/shared/bad_request", error.documentation_url
    assert_equal "e385967f-4298-4240-a971-f988209b32ca", error.request_id
  end

  def test_error_with_no_field_errors
    error = Paddle::ErrorGenerator.new(
      { "error" => { "code" => "simple_error", "detail" => "Simple error message" } },
      500
    )

    assert_equal "Error 500: Simple error message 'simple_error'", error.message
    assert_equal [], error.paddle_errors
    assert_nil error.documentation_url
    assert_nil error.request_id
  end

  def test_service_unavailable_error
    error = Paddle::ErrorFactory.create({}, 503)

    assert_instance_of Paddle::Errors::ServiceUnavailableError, error
    assert_equal "Error 503: The Paddle API is temporarily unavailable. Try again later.", error.message
  end
end
