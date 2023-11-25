public with sharing class MissionAssignmentTriggerHandler {
    private final Boolean triggerIsExecuting;
    private final Integer triggerSize;
    private static final String FAILED_STATUS = System.Label.Failed;
    private static final String COMPLETED_STATUS = System.Label.Completed;
    private static String QUERY_LIST = 'SELECT Id, Status__c, Hero__r.Contact__c FROM Mission_Assignment__c WHERE Mission__c IN MISSION_ID_SET AND Id NOT IN ID_SET';
    public MissionAssignmentTriggerHandler(Boolean triggerIsExecuting, Integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
    }
    public void afterUpdate(
            List<Mission_Assignment__c> newMissionList,
            List<Mission_Assignment__c> oldMissionList,
            Map<Id, Mission_Assignment__c> oldMissionMap,
            Map<Id, Mission_Assignment__c> newMissionMap) {
        missionCompletedHandler(newMissionMap);
    }
    public void beforeUpdate(
            List<Mission_Assignment__c> newMissionList,
            List<Mission_Assignment__c> oldMissionList,
            Map<Id, Mission_Assignment__c> oldMissionMap,
            Map<Id, Mission_Assignment__c> newMissionMap) {
    }

    private static void missionCompletedHandler(Map<Id, Mission_Assignment__c> winnerMap) {
        try {
            Set<Id> winnerIdList = new Set<Id>();
            Set<Id> missionSet = new Set<Id>();
            Set<Id> recipientIds = new Set<Id>();
            for(Mission_Assignment__c mission : winnerMap.values()) {
                if(mission.Status__c == COMPLETED_STATUS) {
                    winnerIdList.add(mission.Id);
                    missionSet.add(mission.Mission__c);
                    recipientIds.add(mission.Hero__r.Contact__c);
                }
            }
            if(winnerIdList.isEmpty()) {
                return;
            }
            String completedEmailTemplateId = Org_Specific_Setting__mdt.getInstance('CompletedEmailTemplateId')?.Value_Text__c;
            String failedEmailTemplateId = Org_Specific_Setting__mdt.getInstance('FailedEmailTemplateId')?.Value_Text__c;
            EmailMissionBatch.getSendEmailResults(winnerIdList,recipientIds, completedEmailTemplateId);
            String query = QUERY_LIST.replace('ID_SET', prepareStringList(winnerIdList)).replace('MISSION_ID_SET', prepareStringList(winnerIdList));
            Database.executeBatch(new EmailMissionBatch(
                query,
                failedEmailTemplateId,
                new Map<String, String> {'Status__c' => FAILED_STATUS},
                'Hero__r.Contact__c')
            );
        } catch (Exception ex) {
            throw new IllegalArgumentException(ex.getMessage());
        }

    }

    public static String prepareStringList(Set<Id> resultString) {
        List<String> stringList = new List<String>();

        for (Id id : resultString) {
            stringList.add('\'' + id + '\'');
        }
        return '(' + String.join(stringList, ', ') + ')';
    }

}