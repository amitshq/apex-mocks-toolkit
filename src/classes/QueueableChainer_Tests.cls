@isTest
private class QueueableChainer_Tests {
  private class RecordingChainer extends QueueableChainer {
    public static List<String> ExecutionOrder = new List<String>();
    private final List<String> remainingSteps;

    RecordingChainer(List<String> remainingSteps) {
      this.remainingSteps = remainingSteps;
    }

    protected override void run() {
      ExecutionOrder.add(this.remainingSteps[0]);
    }

    protected override QueueableChainer getNext() {
      if (this.remainingSteps.size() <= 1) {
        return null;
      }
      List<String> rest = this.remainingSteps.clone();
      rest.remove(0);
      return new RecordingChainer(rest);
    }
  }

  @isTest
  static void it_should_run_and_chain_to_the_next_link_when_headroom_exists() {
    // kept to a single chain hop (2 links) - test context historically
    // restricts queueable chaining depth, and this is the depth every
    // documented version of that restriction allows.
    Test.startTest();
    System.enqueueJob(new RecordingChainer(new List<String>{ 'first', 'second' }));
    Test.stopTest();

    System.assertEquals(new List<String>{ 'first', 'second' }, RecordingChainer.ExecutionOrder);
  }

  @isTest
  static void it_should_stop_and_not_throw_when_no_next_link_is_returned() {
    Test.startTest();
    System.enqueueJob(new RecordingChainer(new List<String>{ 'only' }));
    Test.stopTest();

    System.assertEquals(new List<String>{ 'only' }, RecordingChainer.ExecutionOrder);
  }
}
