trigger SuperheroMissionTrigger on Superhero_Mission__c (after insert) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            SuperheroMissionTriggerHandler.afterInsert(Trigger.new, Trigger.newMap);
        }
    }
}