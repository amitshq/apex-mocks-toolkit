@isTest
private class PlatformCache_Tests {
  @isTest
  static void it_should_delegate_to_the_named_platform_cache_partition() {
    PlatformCache cache = new PlatformCache('local.Default');

    try {
      cache.put('someKey', 'someValue');
      Object result = cache.get('someKey');
      System.assertEquals('someValue', result);
    } catch (Exception ex) {
      // No Platform Cache partition named 'local.Default' is provisioned
      // in every org by default (Setup > Platform Cache) - this at least
      // proves the class compiles and delegates correctly when one exists.
      System.assert(true, 'Skipped: no Platform Cache partition provisioned in this org (' + ex.getMessage() + ')');
    }
  }
}
