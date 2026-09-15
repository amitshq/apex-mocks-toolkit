/**
 * Wraps another ICallout with retry-on-failure: if send() throws, or the
 * response status code is in retryableStatusCodes, it retries up to
 * maxAttempts times before giving up and returning (or re-throwing)
 * whatever the last attempt produced. Each retry is a real callout when
 * wrapping the real Callout implementation, so it spends the
 * transaction's callout limit accordingly.
 */
public class RetryableCallout implements ICallout {
  private final ICallout innerCallout;
  private final Integer maxAttempts;
  private final Set<Integer> retryableStatusCodes;

  public RetryableCallout(ICallout innerCallout, Integer maxAttempts) {
    this(innerCallout, maxAttempts, new Set<Integer>{ 500, 502, 503, 504 });
  }

  public RetryableCallout(ICallout innerCallout, Integer maxAttempts, Set<Integer> retryableStatusCodes) {
    this.innerCallout = innerCallout;
    this.maxAttempts = maxAttempts;
    this.retryableStatusCodes = retryableStatusCodes;
  }

  public HttpResponse send(HttpRequest request) {
    HttpResponse response;
    Exception lastException;
    for (Integer attempt = 1; attempt <= this.maxAttempts; attempt++) {
      try {
        response = this.innerCallout.send(request);
        lastException = null;
        if (this.retryableStatusCodes.contains(response.getStatusCode()) == false) {
          return response;
        }
      } catch (Exception ex) {
        lastException = ex;
      }
    }
    if (lastException != null) {
      throw lastException;
    }
    return response;
  }
}
