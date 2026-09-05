trigger LeadTrigger on Lead (before insert, after insert) {
    new LeadTriggerHandler().run();
}
