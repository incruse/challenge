public with sharing class SuperheroMissionTriggerHandler {
    private static final List<String> EMAIL_TEMPLATE_LIST = new List<String>{'New Special Mission', 'New Public Mission'};

    private static final Map<String, String> QUERY_LIST = new Map<String, String>{
            'NEW_MISSION_ALL' => 'SELECT Id, Contact__c FROM Hero__c',
            'NEW_MISSION_GUILD' => 'SELECT Id, Contact__c, Guild__c, Guild__r.Name FROM Hero__c WHERE Guild__c IN GUILD_ID_SET'
    };
    public static void afterInsert(List<Superhero_Mission__c> newMissionList, Map<Id, Superhero_Mission__c> newMissionMap) {
        newMissionNotification(newMissionList);
    }

    public static void newMissionNotification(List<Superhero_Mission__c> newMissionList) {
        Set<Id> publicMissionSet = new Set<Id>();
        Set<Id> guildSet = new Set<Id>();
        Set<Id> guildsIdSet = new Set<Id>();
        for(Superhero_Mission__c mission : newMissionList) {
            if(mission.Is_Public__c) {
                publicMissionSet.add(mission.Id);
            } else {
                if(mission.Guild__c != null) {
                    guildsIdSet.add(mission.Guild__c);
                    guildSet.add(mission.Id);
                }
            }
        }
        if(!publicMissionSet.isEmpty() && !Test.isRunningTest()) {
            Database.executeBatch(new EmailMissionBatch(
                QUERY_LIST.get('NEW_MISSION_ALL'), EMAIL_TEMPLATE_LIST[1],'Contact__c', publicMissionSet), Limits.getLimitEmailInvocations()
            );
        }
        if(!guildsIdSet.isEmpty() && !Test.isRunningTest()) {
            Database.executeBatch(new EmailMissionBatch(
                QUERY_LIST.get('NEW_MISSION_GUILD').replace('GUILD_ID_SET', MissionAssignmentTriggerHandler.prepareStringList(guildsIdSet)), EMAIL_TEMPLATE_LIST[0],'Contact__c', guildSet), Limits.getLimitEmailInvocations()
            );
        }
    }
}