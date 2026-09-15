/**
 * Wraps a named Platform Cache org partition (Cache.Org). Requires that
 * partition to actually be provisioned in the target org first (Setup >
 * Platform Cache) - without one, real calls throw. CacheMock needs no
 * such setup and is what most tests should use instead.
 */
public virtual class PlatformCache implements ICache {
  private final String partitionName;

  public PlatformCache(String partitionName) {
    this.partitionName = partitionName;
  }

  public virtual Object get(String key) {
    return this.getPartition().get(key);
  }

  public virtual void put(String key, Object value) {
    this.getPartition().put(key, value);
  }

  public virtual void put(String key, Object value, Integer ttlSeconds) {
    this.getPartition().put(key, value, ttlSeconds);
  }

  public virtual Boolean contains(String key) {
    return this.getPartition().contains(key);
  }

  public virtual void remove(String key) {
    this.getPartition().remove(key);
  }

  private Cache.OrgPartition getPartition() {
    return Cache.Org.getPartition(this.partitionName);
  }
}
