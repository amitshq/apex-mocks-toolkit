@isTest
private class LeadReassignmentBatch_Tests {
  @isTest
  static void it_should_process_a_batch_directly_without_real_dml() {
    Id repId = TestingUtils.generateId(User.SObjectType);
    LeadReassignmentBatch batch = new LeadReassignmentBatch(
      new UnitOfWork(CrudMock.getMock()),
      new RoundRobinAssigner(),
      new List<Id>{ repId }
    );
    List<SObject> leads = new List<SObject>{
      new Lead(Id = TestingUtils.generateId(Lead.SObjectType), LastName = 'Test', Company = 'Acme')
    };

    batch.processBatch(leads);

    System.assertEquals(repId, ((Lead) leads[0]).OwnerId);
    System.assertEquals(1, CrudMock.Updated.size());
  }

  @isTest
  static void it_should_skip_processing_when_no_reps_are_configured() {
    LeadReassignmentBatch batch = new LeadReassignmentBatch(new UnitOfWork(CrudMock.getMock()), new RoundRobinAssigner(), new List<Id>());
    List<SObject> leads = new List<SObject>{
      new Lead(Id = TestingUtils.generateId(Lead.SObjectType), LastName = 'Test', Company = 'Acme')
    };

    batch.processBatch(leads);

    System.assertEquals(0, CrudMock.Updated.size());
  }

  @isTest
  static void it_should_reassign_leads_via_a_real_batch_run() {
    insert new Lead(LastName = 'Test', Company = 'Acme');

    Test.startTest();
    Database.executeBatch(new LeadReassignmentBatch(new List<Id>{ UserInfo.getUserId() }), 200);
    Test.stopTest();

    Lead lead = [SELECT OwnerId FROM Lead WHERE LastName = 'Test'];
    System.assertEquals(UserInfo.getUserId(), lead.OwnerId);
  }
}
