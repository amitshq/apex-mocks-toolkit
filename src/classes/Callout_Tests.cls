@isTest
private class Callout_Tests {
  private class FakeHttpCalloutMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request) {
      HttpResponse response = new HttpResponse();
      response.setStatusCode(200);
      response.setBody('{"ok":true}');
      return response;
    }
  }

  @isTest
  static void it_should_send_a_real_http_request_and_return_the_response() {
    Test.setMock(HttpCalloutMock.class, new FakeHttpCalloutMock());
    HttpRequest request = new HttpRequest();
    request.setEndpoint('https://example.com/api');
    request.setMethod('GET');

    HttpResponse response = new Callout().send(request);

    System.assertEquals(200, response.getStatusCode());
    System.assertEquals('{"ok":true}', response.getBody());
  }
}
