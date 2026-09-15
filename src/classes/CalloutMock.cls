/**
 * In-memory ICallout for tests - no Test.setMock/HttpCalloutMock ceremony
 * needed in consuming code, since a real Http().send() never happens.
 * Configure per-endpoint responses with respondWith(), or a catch-all
 * with respondWithDefault(). Every sent request is recorded to a static
 * list, same spirit as CrudMock's recorded DML calls.
 */
public virtual class CalloutMock implements ICallout {
  public static List<HttpRequest> SentRequests = new List<HttpRequest>();

  private final Map<String, HttpResponse> responseByEndpoint = new Map<String, HttpResponse>();
  private HttpResponse defaultResponse;

  public void respondWith(String endpoint, HttpResponse response) {
    this.responseByEndpoint.put(endpoint, response);
  }

  public void respondWithDefault(HttpResponse response) {
    this.defaultResponse = response;
  }

  public virtual HttpResponse send(HttpRequest request) {
    SentRequests.add(request);
    if (this.responseByEndpoint.containsKey(request.getEndpoint())) {
      return this.responseByEndpoint.get(request.getEndpoint());
    }
    if (this.defaultResponse != null) {
      return this.defaultResponse;
    }
    throw new CalloutMockException('No mock response configured for endpoint: ' + request.getEndpoint());
  }

  public class CalloutMockException extends Exception {
  }
}
