public with sharing class MissionAssignmentTriggerHandler {
    private static final String COMPLETED_STATUS = 'Completed';
    public static void beforeUpdate(
            List<Mission_Assignment__c> newMissionList,
            List<Mission_Assignment__c> oldMissionList,
            Map<Id, Mission_Assignment__c> newMissionMap,
            Map<Id, Mission_Assignment__c> oldMissionMap) {
        missionCompletedHandler(newMissionList);
    }

    private static void missionCompletedHandler(List<Mission_Assignment__c> newMissionList) {
        try {
            for(Mission_Assignment__c mission : newMissionList) {
                if(mission.Status__c != COMPLETED_STATUS) {
                    return;
                }
            }

//            if(!Test.isRunningTest()) {
                Database.executeBatch(new EmailMissionBatch(
                    'COMPLETED_THE_MISSION',
                    new Set<Mission_Assignment__c>(newMissionList)
                ), Limits.getLimitEmailInvocations()
                );
//            }

//            if(!Test.isRunningTest()) {
                Database.executeBatch(new EmailMissionBatch(
                    'FAILED_THE_MISSION',
                    new Set<Mission_Assignment__c>(newMissionList)
                ), Limits.getLimitEmailInvocations()
                );
//            }
        } catch (Exception ex) {
            throw new IllegalArgumentException(ex.getMessage());
        }

    }
}