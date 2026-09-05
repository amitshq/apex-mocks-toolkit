@isTest
private class LeadTriggerHandler_Tests {
    @isTest
    static void it_should_round_robin_assign_new_leads_to_configured_sales_reps() {
        LeadAssignmentConfig.salesRepIds = new List<Id>{ UserInfo.getUserId() };

        insert new List<Lead>{
            new Lead(LastName = 'Test1', Company = 'Test Co'),
            new Lead(LastName = 'Test2', Company = 'Test Co')
        };

        List<Lead> leads = [SELECT OwnerId FROM Lead WHERE LastName IN ('Test1', 'Test2')];
        System.assertEquals(2, leads.size());
        for(Lead lead : leads) {
            System.assertEquals(UserInfo.getUserId(), lead.OwnerId);
        }
    }

    @isTest
    static void it_should_create_a_follow_up_task_owned_by_the_assigned_rep() {
        LeadAssignmentConfig.salesRepIds = new List<Id>{ UserInfo.getUserId() };

        insert new Lead(LastName = 'Test', Company = 'Test Co');

        Lead lead = [SELECT Id, OwnerId FROM Lead WHERE LastName = 'Test'];
        List<Task> followUps = [SELECT OwnerId, WhoId FROM Task WHERE WhoId = :lead.Id];
        System.assertEquals(1, followUps.size());
        System.assertEquals(lead.OwnerId, followUps[0].OwnerId);
    }

    @isTest
    static void it_should_not_fail_when_no_sales_reps_are_configured() {
        LeadAssignmentConfig.salesRepIds = new List<Id>();

        try {
            insert new Lead(LastName = 'Test', Company = 'Test Co');
        } catch(Exception ex) {
            System.assert(false, 'Expected the trigger to no-op safely without configured sales reps: ' + ex);
        }
    }

    @isTest
    static void it_should_assign_leads_directly_via_beforeinsert_without_real_dml() {
        Id repId = UserInfo.getUserId();
        LeadTriggerHandler handler = new LeadTriggerHandler(new UnitOfWork(CrudMock.getMock()), new RoundRobinAssigner(), new List<Id>{ repId });
        List<SObject> leads = new List<SObject>{ new Lead(LastName = 'Test', Company = 'Test Co') };

        handler.beforeInsert(leads);

        System.assertEquals(repId, ((Lead) leads[0]).OwnerId);
    }

    @isTest
    static void it_should_skip_assignment_in_beforeinsert_when_no_reps_are_configured() {
        LeadTriggerHandler handler = new LeadTriggerHandler(new UnitOfWork(CrudMock.getMock()), new RoundRobinAssigner(), new List<Id>());
        List<SObject> leads = new List<SObject>{ new Lead(LastName = 'Test', Company = 'Test Co') };

        handler.beforeInsert(leads);

        System.assertEquals(null, ((Lead) leads[0]).OwnerId);
    }

    @isTest
    static void it_should_queue_a_follow_up_task_via_the_unit_of_work_in_afterinsert() {
        Id repId = TestingUtils.generateId(User.SObjectType);
        LeadTriggerHandler handler = new LeadTriggerHandler(new UnitOfWork(CrudMock.getMock()), new RoundRobinAssigner(), new List<Id>{ repId });
        Lead lead = new Lead(Id = TestingUtils.generateId(Lead.SObjectType), LastName = 'Test', Company = 'Test Co', OwnerId = repId);

        handler.afterInsert(new List<SObject>{ lead });

        System.assertEquals(1, CrudMock.Inserted.size());
        Task queuedTask = (Task) CrudMock.Inserted.firstOrDefault;
        System.assertEquals(lead.Id, queuedTask.WhoId);
        System.assertEquals(repId, queuedTask.OwnerId);
    }

    @isTest
    static void it_should_skip_the_follow_up_task_in_afterinsert_when_no_reps_are_configured() {
        LeadTriggerHandler handler = new LeadTriggerHandler(new UnitOfWork(CrudMock.getMock()), new RoundRobinAssigner(), new List<Id>());
        Lead lead = new Lead(Id = TestingUtils.generateId(Lead.SObjectType), LastName = 'Test', Company = 'Test Co');

        handler.afterInsert(new List<SObject>{ lead });

        System.assertEquals(0, CrudMock.Inserted.size());
    }
}
