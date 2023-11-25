trigger MissionAssignmentTrigger on Mission_Assignment__c (after update, before update) {
    if (Org_Specific_Setting__mdt.getInstance('Run_All_Triggers')?.Value_Checkbox__c == true) {
        MissionAssignmentTriggerHandler handler = new MissionAssignmentTriggerHandler(Trigger.isExecuting, Trigger.size);
        switch on Trigger.operationType {
            when AFTER_UPDATE {
                handler.afterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            }
            when BEFORE_UPDATE {
                handler.beforeUpdate(Trigger.new, Trigger.old, Trigger.oldMap, Trigger.newMap);
            }
        }
    }
}