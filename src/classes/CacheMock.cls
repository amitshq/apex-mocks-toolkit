/**
 * In-memory ICache backed by a plain Map - no Platform Cache partition
 * provisioning needed, unlike PlatformCache. What tests (and demos like
 * CachedRoundRobinAssigner's) should use.
 */
public virtual class CacheMock implements ICache {
  private final Map<String, Object> valuesByKey = new Map<String, Object>();

  public virtual Object get(String key) {
    return this.valuesByKey.get(key);
  }

  public virtual void put(String key, Object value) {
    this.valuesByKey.put(key, value);
  }

  public virtual void put(String key, Object value, Integer ttlSeconds) {
    this.put(key, value);
  }

  public virtual Boolean contains(String key) {
    return this.valuesByKey.containsKey(key);
  }

  public virtual void remove(String key) {
    this.valuesByKey.remove(key);
  }
}
