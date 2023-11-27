trigger MissionAssignmentTrigger on Mission_Assignment__c (after update, before update) {
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            MissionAssignmentTriggerHandler.afterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
    }
}