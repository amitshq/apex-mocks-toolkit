@isTest
private class EventPublisher_Tests {
  @isTest
  static void it_should_publish_a_real_platform_event() {
    Lead_Assigned__e event = new Lead_Assigned__e(Lead_Id__c = '00Q000000000001AAA', Assignee_Id__c = UserInfo.getUserId());

    List<Database.SaveResult> results = new EventPublisher().publish(new List<SObject>{ event });

    System.assertEquals(1, results.size());
    System.assert(results[0].isSuccess());
  }
}
