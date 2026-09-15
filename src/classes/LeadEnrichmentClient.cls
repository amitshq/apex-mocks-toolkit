/**
 * Worked example for the callout layer: looks up a Lead's Industry from
 * its Company name via an external API. Wraps its ICallout in a
 * RetryableCallout by default, since an external dependency like this is
 * exactly the kind of thing worth retrying on transient failures.
 */
public class LeadEnrichmentClient {
  private final ICallout callout;
  private final String baseEndpoint;

  public LeadEnrichmentClient(String baseEndpoint) {
    this(new RetryableCallout(Application.Callout.newInstance(), 3), baseEndpoint);
  }

  @testVisible
  private LeadEnrichmentClient(ICallout callout, String baseEndpoint) {
    this.callout = callout;
    this.baseEndpoint = baseEndpoint;
  }

  public String getIndustryFor(String companyName) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(this.baseEndpoint + '?company=' + EncodingUtil.urlEncode(companyName, 'UTF-8'));
    request.setMethod('GET');

    HttpResponse response = this.callout.send(request);
    if (response.getStatusCode() != 200) {
      throw new LeadEnrichmentException('Enrichment lookup failed with status ' + response.getStatusCode());
    }

    Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    return (String) body.get('industry');
  }

  public class LeadEnrichmentException extends Exception {
  }
}
