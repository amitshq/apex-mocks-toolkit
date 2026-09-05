/**
 * In-memory ISelector for tests: seed() canned records, then selectById
 * returns whichever of them match the requested Ids - no SOQL, same
 * spirit as CrudMock on the write side. Tracks a call count so tests (and
 * the benchmark in ApexMocksTests) can assert on invocation volume.
 */
public virtual class SelectorMock implements ISelector {
    public Integer selectByIdCallCount { get; private set; }
    private final Map<Id, SObject> recordsById = new Map<Id, SObject>();

    public SelectorMock() {
        this.selectByIdCallCount = 0;
    }

    public void seed(List<SObject> records) {
        for(SObject record : records) {
            this.recordsById.put(record.Id, record);
        }
    }

    public virtual List<SObject> selectById(Set<Id> recordIds) {
        this.selectByIdCallCount++;
        List<SObject> matches = new List<SObject>();
        for(Id recordId : recordIds) {
            if(this.recordsById.containsKey(recordId)) {
                matches.add(this.recordsById.get(recordId));
            }
        }
        return matches;
    }
}
