@isTest
private class GovernorLimitGuard_Tests {
  @isTest
  static void it_should_report_a_non_negative_percent_used_before_any_dml() {
    GovernorLimitGuard guard = new GovernorLimitGuard();

    System.assert(guard.getDmlRowsPercentUsed() >= 0);
  }

  @isTest
  static void it_should_report_increased_dml_rows_usage_after_a_dml_statement() {
    GovernorLimitGuard guard = new GovernorLimitGuard();
    Decimal before = guard.getDmlRowsPercentUsed();

    insert new Account(Name = 'Test');

    Decimal after = guard.getDmlRowsPercentUsed();
    System.assert(after > before);
  }

  @isTest
  static void it_should_not_throw_when_usage_is_below_the_threshold() {
    GovernorLimitGuard guard = new GovernorLimitGuard();

    try {
      guard.throwIfDmlRowsNear(99);
    } catch (GovernorLimitGuard.LimitGuardException ex) {
      System.assert(false, 'Did not expect a LimitGuardException this early in the transaction: ' + ex);
    }
  }

  @isTest
  static void it_should_throw_when_usage_is_at_or_above_the_threshold() {
    GovernorLimitGuard guard = new GovernorLimitGuard();

    try {
      guard.throwIfCpuTimeNear(0);
      System.assert(false, 'Expected a LimitGuardException to be thrown');
    } catch (GovernorLimitGuard.LimitGuardException ex) {
      System.assert(true);
    }
  }

  private class NoOpQueueable implements Queueable {
    public void execute(QueueableContext context) {
    }
  }

  @isTest
  static void it_should_report_increased_queueable_usage_after_enqueuing_a_job() {
    GovernorLimitGuard guard = new GovernorLimitGuard();
    Decimal before = guard.getQueueableJobsPercentUsed();

    System.enqueueJob(new NoOpQueueable());

    Decimal after = guard.getQueueableJobsPercentUsed();
    System.assert(after > before);
  }
}
