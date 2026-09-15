@isTest
private class BatchBase_Tests {
  private class RecordingBatch extends BatchBase {
    public static Integer FinishedWithTotal = -1;

    protected override Database.QueryLocator getQueryLocator() {
      return Database.getQueryLocator([SELECT Id FROM Account]);
    }

    protected override void processBatch(List<SObject> records) {
    }

    protected override void onFinish(Integer totalProcessed) {
      FinishedWithTotal = totalProcessed;
    }
  }

  @isTest
  static void it_should_track_total_processed_records_and_call_onfinish() {
    insert new List<Account>{ new Account(Name = '1'), new Account(Name = '2'), new Account(Name = '3') };

    Test.startTest();
    Database.executeBatch(new RecordingBatch(), 200);
    Test.stopTest();

    System.assertEquals(3, RecordingBatch.FinishedWithTotal);
  }

  @isTest
  static void it_should_report_zero_processed_when_there_is_nothing_to_batch() {
    Test.startTest();
    Database.executeBatch(new RecordingBatch(), 200);
    Test.stopTest();

    System.assertEquals(0, RecordingBatch.FinishedWithTotal);
  }
}
