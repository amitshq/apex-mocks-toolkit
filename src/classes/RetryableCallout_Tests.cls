@isTest
private class RetryableCallout_Tests {
  private class FlakyCallout implements ICallout {
    private final List<HttpResponse> responsesInOrder;
    private Integer callCount = 0;

    FlakyCallout(List<HttpResponse> responsesInOrder) {
      this.responsesInOrder = responsesInOrder;
    }

    public HttpResponse send(HttpRequest request) {
      HttpResponse response = this.responsesInOrder[Math.min(this.callCount, this.responsesInOrder.size() - 1)];
      this.callCount++;
      return response;
    }

    public Integer getCallCount() {
      return this.callCount;
    }
  }

  private class ThrowsOnceCallout implements ICallout {
    private Boolean hasThrown = false;

    public HttpResponse send(HttpRequest request) {
      if (this.hasThrown == false) {
        this.hasThrown = true;
        throw new CalloutException('Simulated network failure');
      }
      HttpResponse response = new HttpResponse();
      response.setStatusCode(200);
      return response;
    }
  }

  private static HttpResponse responseWithStatus(Integer statusCode) {
    HttpResponse response = new HttpResponse();
    response.setStatusCode(statusCode);
    return response;
  }

  @isTest
  static void it_should_return_immediately_on_a_non_retryable_status() {
    FlakyCallout flaky = new FlakyCallout(new List<HttpResponse>{ responseWithStatus(200) });
    RetryableCallout retryable = new RetryableCallout(flaky, 3);

    HttpResponse response = retryable.send(new HttpRequest());

    System.assertEquals(200, response.getStatusCode());
    System.assertEquals(1, flaky.getCallCount());
  }

  @isTest
  static void it_should_retry_on_a_retryable_status_and_return_the_eventual_success() {
    FlakyCallout flaky = new FlakyCallout(
      new List<HttpResponse>{ responseWithStatus(503), responseWithStatus(503), responseWithStatus(200) }
    );
    RetryableCallout retryable = new RetryableCallout(flaky, 3);

    HttpResponse response = retryable.send(new HttpRequest());

    System.assertEquals(200, response.getStatusCode());
    System.assertEquals(3, flaky.getCallCount());
  }

  @isTest
  static void it_should_give_up_after_maxattempts_and_return_the_last_response() {
    FlakyCallout flaky = new FlakyCallout(new List<HttpResponse>{ responseWithStatus(503) });
    RetryableCallout retryable = new RetryableCallout(flaky, 2);

    HttpResponse response = retryable.send(new HttpRequest());

    System.assertEquals(503, response.getStatusCode());
    System.assertEquals(2, flaky.getCallCount());
  }

  @isTest
  static void it_should_retry_after_a_thrown_exception_and_return_the_eventual_success() {
    RetryableCallout retryable = new RetryableCallout(new ThrowsOnceCallout(), 2);

    HttpResponse response = retryable.send(new HttpRequest());

    System.assertEquals(200, response.getStatusCode());
  }
}
