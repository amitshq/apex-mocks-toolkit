@isTest
private class CacheMock_Tests {
  @isTest
  static void it_should_return_null_for_a_key_that_was_never_put() {
    CacheMock cache = new CacheMock();

    System.assertEquals(null, cache.get('missing'));
  }

  @isTest
  static void it_should_return_the_stored_value_for_a_key() {
    CacheMock cache = new CacheMock();

    cache.put('key', 'value');

    System.assertEquals('value', cache.get('key'));
  }

  @isTest
  static void it_should_report_contains_correctly() {
    CacheMock cache = new CacheMock();
    cache.put('key', 'value');

    System.assert(cache.contains('key'));
    System.assert(cache.contains('missing') == false);
  }

  @isTest
  static void it_should_remove_a_stored_value() {
    CacheMock cache = new CacheMock();
    cache.put('key', 'value');

    cache.remove('key');

    System.assertEquals(null, cache.get('key'));
    System.assert(cache.contains('key') == false);
  }

  @isTest
  static void it_should_accept_a_ttl_without_erroring_and_ignore_it() {
    CacheMock cache = new CacheMock();

    cache.put('key', 'value', 300);

    System.assertEquals('value', cache.get('key'));
  }
}
