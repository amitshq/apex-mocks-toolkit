/**
 * This whole repo exists because a mocking library once ran a transaction
 * out of governor limits. This class makes headroom checkable instead of
 * discovering it via a thrown System.LimitException: read a limit's percent
 * used, or throw proactively once it crosses a threshold you choose.
 */
public class GovernorLimitGuard {
    public Decimal getDmlRowsPercentUsed() {
        return this.percentUsed(Limits.getDmlRows(), Limits.getLimitDmlRows());
    }

    public Decimal getDmlStatementsPercentUsed() {
        return this.percentUsed(Limits.getDmlStatements(), Limits.getLimitDmlStatements());
    }

    public Decimal getQueriesPercentUsed() {
        return this.percentUsed(Limits.getQueries(), Limits.getLimitQueries());
    }

    public Decimal getQueryRowsPercentUsed() {
        return this.percentUsed(Limits.getQueryRows(), Limits.getLimitQueryRows());
    }

    public Decimal getCpuTimePercentUsed() {
        return this.percentUsed(Limits.getCpuTime(), Limits.getLimitCpuTime());
    }

    public Decimal getHeapSizePercentUsed() {
        return this.percentUsed(Limits.getHeapSize(), Limits.getLimitHeapSize());
    }

    public void throwIfDmlRowsNear(Decimal thresholdPercent) {
        this.throwIfNear('DML rows', this.getDmlRowsPercentUsed(), thresholdPercent);
    }

    public void throwIfQueriesNear(Decimal thresholdPercent) {
        this.throwIfNear('SOQL queries', this.getQueriesPercentUsed(), thresholdPercent);
    }

    public void throwIfCpuTimeNear(Decimal thresholdPercent) {
        this.throwIfNear('CPU time', this.getCpuTimePercentUsed(), thresholdPercent);
    }

    private Decimal percentUsed(Integer used, Integer limit) {
        return limit == 0 ? 0 : (Decimal.valueOf(used) / Decimal.valueOf(limit)) * 100;
    }

    private void throwIfNear(String limitName, Decimal percentUsed, Decimal thresholdPercent) {
        if(percentUsed >= thresholdPercent) {
            throw new LimitGuardException(limitName + ' usage at ' + percentUsed.setScale(1) + '%, at or above the ' + thresholdPercent + '% threshold');
        }
    }

    public class LimitGuardException extends Exception {}
}
