@isTest
private class EventPublisherMock_Tests {
  @isTest
  static void it_should_record_published_events_without_a_real_publish() {
    EventPublisherMock mock = new EventPublisherMock();
    Lead_Assigned__e event = new Lead_Assigned__e(Lead_Id__c = '00Q000000000001AAA', Assignee_Id__c = UserInfo.getUserId());

    mock.publish(new List<SObject>{ event });

    System.assertEquals(1, EventPublisherMock.PublishedEvents.size());
  }

  @isTest
  static void it_should_return_an_empty_result_list() {
    EventPublisherMock mock = new EventPublisherMock();

    List<Database.SaveResult> results = mock.publish(new List<SObject>());

    System.assertEquals(0, results.size());
  }
}
