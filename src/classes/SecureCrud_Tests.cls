@isTest
private class SecureCrud_Tests {
    @isTest
    static void it_should_insert_like_crud_when_fields_are_accessible() {
        Contact contact = new Contact(LastName = 'Test');

        new SecureCrud().doInsert(contact);

        System.assertNotEquals(null, contact.Id);
    }

    @isTest
    static void it_should_update_like_crud_when_fields_are_accessible() {
        Contact contact = new Contact(LastName = 'Test');
        new SecureCrud().doInsert(contact);
        contact.FirstName = 'Harry';

        new SecureCrud().doUpdate(contact);

        Contact updated = [SELECT FirstName FROM Contact WHERE Id = :contact.Id];
        System.assertEquals('Harry', updated.FirstName);
    }

    @isTest
    static void it_should_upsert_like_crud() {
        Contact contact = new Contact(LastName = 'Test');

        new SecureCrud().doUpsert(contact);

        System.assertNotEquals(null, contact.Id);
    }

    @isTest
    static void it_should_delete_when_the_object_is_deletable() {
        Account account = new Account(Name = 'Test');
        new SecureCrud().doInsert(account);

        new SecureCrud().doDelete(account);

        List<Account> remaining = [SELECT Id FROM Account WHERE Id = :account.Id];
        System.assert(remaining.isEmpty());
    }

    @isTest
    static void it_should_expose_the_last_access_decision_after_a_dml_call() {
        SecureCrud crud = new SecureCrud();
        Contact contact = new Contact(LastName = 'Test');

        crud.doInsert(contact);

        // Proves Security.stripInaccessible actually ran, regardless of what
        // (if anything) the running user's permissions caused it to strip -
        // that part is inherently org/profile-dependent and isn't asserted here.
        System.assertNotEquals(null, crud.getLastAccessDecision());
    }

    @isTest
    static void it_should_throw_when_the_object_type_is_not_deletable() {
        // Users can never be deleted via the API/UI regardless of permissions,
        // so this is a deterministic, org-independent way to exercise the
        // "object isn't deletable" guard without needing custom permission setup.
        User currentUser = new User(Id = UserInfo.getUserId());

        try {
            new SecureCrud().doDelete(currentUser);
            System.assert(false, 'Expected a SecureCrud.SecureCrudException to be thrown');
        } catch(SecureCrud.SecureCrudException ex) {
            System.assert(ex.getMessage().contains('User'));
        }
    }
}
