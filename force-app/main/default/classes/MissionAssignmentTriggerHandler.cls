public with sharing class MissionAssignmentTriggerHandler {
    private static final String FAILED_STATUS = System.Label.Failed;
    private static final String COMPLETED_STATUS = System.Label.Completed;
    private static final List<String> EMAIL_TEMPLATE_LIST = new List<String>{'Complete the Mission', 'Failed the Mission'};
    private static List<String> QUERY_LIST = new List<String>{'SELECT Id, Status__c, Hero__r.Contact__c, Mission__c, Mission__r.Reward__c FROM Mission_Assignment__c WHERE Mission__c IN MISSIONS AND Id NOT IN ID_SET',
                                                              'SELECT Id, Status__c, Hero__r.Contact__c, Mission__c, Mission__r.Reward__c FROM Mission_Assignment__c WHERE Id IN ID_SET'};
    public static void afterUpdate(
            List<Mission_Assignment__c> newMissionList,
            List<Mission_Assignment__c> oldMissionList,
            Map<Id, Mission_Assignment__c> oldMissionMap,
            Map<Id, Mission_Assignment__c> newMissionMap) {
        missionCompletedHandler(newMissionMap);
    }

    private static void missionCompletedHandler(Map<Id, Mission_Assignment__c> winnerMap) {
        try {
            Set<Id> winnerIdList = new Set<Id>();
            Set<Id> missionIdSet = new Set<Id>();
            Set<Id> recipientIds = new Set<Id>();
            Map<Id, Id> emailRecipientRecordMap = new Map<Id, Id>();

            for(Mission_Assignment__c mission : getAssignmentsSOQL(winnerMap.keySet())) {
                if(mission.Status__c == COMPLETED_STATUS) {
                    winnerIdList.add(mission.Id);
                    missionIdSet.add(mission.Mission__c);
                }
                recipientIds.add(mission.Hero__r.Contact__c);
                emailRecipientRecordMap.put(mission.Hero__r.Contact__c, mission.Mission__c);
            }
            if(winnerIdList.isEmpty()) {
                return;
            }
            List<EmailTemplate> emailTemplateList = [SELECT Id FROM EmailTemplate WHERE Name IN : EMAIL_TEMPLATE_LIST ORDER BY Name ASC LIMIT 2];
            if(emailTemplateList.size() < 2) {
                throw new IllegalArgumentException('Email Templates not found');
            }

            if(!winnerIdList.isEmpty() && !Test.isRunningTest()) {
                Database.executeBatch(new EmailMissionBatch(
                    QUERY_LIST[1].replace('ID_SET', prepareStringList(winnerIdList)),
                    emailTemplateList[0].Id,
                    'Hero__r.Contact__c',
                    missionIdSet
                    )
                );
            }

            if(!winnerIdList.isEmpty() && !Test.isRunningTest()) {
                Database.executeBatch(new EmailMissionBatch(
                    QUERY_LIST[0].replace('ID_SET', prepareStringList(winnerIdList)).replace('MISSIONS', prepareStringList(winnerIdList)),
                    emailTemplateList[1].Id,
                    new Map<String, String> {'Status__c' => FAILED_STATUS},
                    'Hero__r.Contact__c',
                    missionIdSet)
                );
            }
        } catch (Exception ex) {
            throw new IllegalArgumentException(ex.getMessage());
        }

    }

    private static List<Mission_Assignment__c> getAssignmentsSOQL(Set<Id> heroIds) {
        return [SELECT Id, Status__c, Mission__c, Hero__r.Contact__c, Hero__c FROM Mission_Assignment__c WHERE Id IN: heroIds];
    }

    public static String prepareStringList(Set<Id> resultString) {
        List<String> stringList = new List<String>();

        for (Id id : resultString) {
            stringList.add('\'' + id + '\'');
        }
        return '(' + String.join(stringList, ', ') + ')';
    }

}