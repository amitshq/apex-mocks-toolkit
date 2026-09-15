/**
 * Fulfils RoundRobinAssigner's own doc comment: wraps it plus an ICache
 * to actually persist and resume the round-robin index across
 * transactions, instead of leaving that as an exercise for the caller.
 * Reads the last index before assigning, writes the next one back after.
 */
public class CachedRoundRobinAssigner implements IAssigner {
  private final RoundRobinAssigner assigner;
  private final ICache cache;
  private final String cacheKey;

  public CachedRoundRobinAssigner(ICache cache, String cacheKey) {
    this.assigner = new RoundRobinAssigner();
    this.cache = cache;
    this.cacheKey = cacheKey;
  }

  public void assign(List<SObject> records, List<Id> assigneeIds, Schema.SObjectField ownerField) {
    Object cachedIndex = this.cache.get(this.cacheKey);
    Integer startIndex = cachedIndex == null ? 0 : (Integer) cachedIndex;
    Integer nextIndex = this.assigner.assign(records, assigneeIds, ownerField, startIndex);
    this.cache.put(this.cacheKey, nextIndex);
  }
}
