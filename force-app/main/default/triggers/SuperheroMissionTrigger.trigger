trigger SuperheroMissionTrigger on Superhero_Mission__c (before insert, before update, after insert, after update) {
    if (Org_Specific_Setting__mdt.getInstance('Run_All_Triggers')?.Value_Checkbox__c == true) {
        SuperheroMissionTriggerHandler handler = new SuperheroMissionTriggerHandler(Trigger.isExecuting, Trigger.size);
        switch on Trigger.operationType {
            when AFTER_INSERT {
                handler.afterInsert(Trigger.new, Trigger.newMap);
            }
        }
    }
}