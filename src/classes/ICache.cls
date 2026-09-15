public interface ICache {
  Object get(String key);
  void put(String key, Object value);
  void put(String key, Object value, Integer ttlSeconds);
  Boolean contains(String key);
  void remove(String key);
}
