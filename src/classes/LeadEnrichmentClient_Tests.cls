@isTest
private class LeadEnrichmentClient_Tests {
  @isTest
  static void it_should_return_the_industry_from_a_successful_response() {
    CalloutMock mockCallout = new CalloutMock();
    HttpResponse response = new HttpResponse();
    response.setStatusCode(200);
    response.setBody('{"industry":"Technology"}');
    mockCallout.respondWithDefault(response);
    LeadEnrichmentClient client = new LeadEnrichmentClient(mockCallout, 'https://api.example.com/lookup');

    String industry = client.getIndustryFor('Acme');

    System.assertEquals('Technology', industry);
  }

  @isTest
  static void it_should_throw_when_the_response_is_not_successful() {
    CalloutMock mockCallout = new CalloutMock();
    HttpResponse response = new HttpResponse();
    response.setStatusCode(500);
    mockCallout.respondWithDefault(response);
    LeadEnrichmentClient client = new LeadEnrichmentClient(mockCallout, 'https://api.example.com/lookup');

    try {
      client.getIndustryFor('Acme');
      System.assert(false, 'Expected a LeadEnrichmentClient.LeadEnrichmentException to be thrown');
    } catch (LeadEnrichmentClient.LeadEnrichmentException ex) {
      System.assert(true);
    }
  }

  @isTest
  static void it_should_url_encode_the_company_name_in_the_endpoint() {
    CalloutMock mockCallout = new CalloutMock();
    HttpResponse response = new HttpResponse();
    response.setStatusCode(200);
    response.setBody('{"industry":"Technology"}');
    mockCallout.respondWithDefault(response);
    LeadEnrichmentClient client = new LeadEnrichmentClient(mockCallout, 'https://api.example.com/lookup');

    client.getIndustryFor('Acme & Co');

    System.assertEquals(1, CalloutMock.SentRequests.size());
    System.assert(CalloutMock.SentRequests[0].getEndpoint().contains('Acme'));
  }
}
