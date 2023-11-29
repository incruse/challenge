trigger MissionAssignmentTrigger on Mission_Assignment__c (before update) {
    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            MissionAssignmentTriggerHandler.beforeUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        }
    }
}