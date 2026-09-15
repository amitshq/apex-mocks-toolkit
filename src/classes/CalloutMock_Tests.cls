@isTest
private class CalloutMock_Tests {
  @isTest
  static void it_should_return_the_configured_response_for_a_matching_endpoint() {
    CalloutMock mock = new CalloutMock();
    HttpResponse canned = new HttpResponse();
    canned.setStatusCode(200);
    canned.setBody('ok');
    mock.respondWith('https://example.com/api', canned);
    HttpRequest request = new HttpRequest();
    request.setEndpoint('https://example.com/api');
    request.setMethod('GET');

    HttpResponse response = mock.send(request);

    System.assertEquals(200, response.getStatusCode());
    System.assertEquals('ok', response.getBody());
    System.assertEquals(1, CalloutMock.SentRequests.size());
  }

  @isTest
  static void it_should_return_the_default_response_when_no_endpoint_matches() {
    CalloutMock mock = new CalloutMock();
    HttpResponse defaultResponse = new HttpResponse();
    defaultResponse.setStatusCode(404);
    mock.respondWithDefault(defaultResponse);
    HttpRequest request = new HttpRequest();
    request.setEndpoint('https://example.com/unregistered');
    request.setMethod('GET');

    HttpResponse response = mock.send(request);

    System.assertEquals(404, response.getStatusCode());
  }

  @isTest
  static void it_should_throw_when_no_response_is_configured_at_all() {
    CalloutMock mock = new CalloutMock();
    HttpRequest request = new HttpRequest();
    request.setEndpoint('https://example.com/unregistered');
    request.setMethod('GET');

    try {
      mock.send(request);
      System.assert(false, 'Expected a CalloutMock.CalloutMockException to be thrown');
    } catch (CalloutMock.CalloutMockException ex) {
      System.assert(true);
    }
  }

  @isTest
  static void it_should_record_every_sent_request() {
    CalloutMock mock = new CalloutMock();
    mock.respondWithDefault(new HttpResponse());
    HttpRequest requestOne = new HttpRequest();
    requestOne.setEndpoint('https://example.com/one');
    requestOne.setMethod('GET');
    HttpRequest requestTwo = new HttpRequest();
    requestTwo.setEndpoint('https://example.com/two');
    requestTwo.setMethod('POST');

    mock.send(requestOne);
    mock.send(requestTwo);

    System.assertEquals(2, CalloutMock.SentRequests.size());
  }
}
