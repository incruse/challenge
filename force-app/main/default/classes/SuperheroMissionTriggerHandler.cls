public with sharing class SuperheroMissionTriggerHandler {
    private final Boolean triggerIsExecuting;
    private final Integer triggerSize;
    private static final Map<String, String> QUERY_LIST = new Map<String, String>{
            'NEW_MISSION_ALL' => 'SELECT Id, Contact__c FROM Hero__c',
            'NEW_MISSION_GUILD' => 'SELECT Id, Contact__c, Guild__c, Guild__r.Name FROM Hero__c WHERE Guild__c IN GUILD_ID_SET'
    };
    public SuperheroMissionTriggerHandler(Boolean triggerIsExecuting, Integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
    }
    public void afterInsert(List<Superhero_Mission__c> newMissionList, Map<Id, Superhero_Mission__c> newMissionMap) {
        newMissionNotification(newMissionList);
    }

    public static void newMissionNotification(List<Superhero_Mission__c> newMissionList) {
        String newPublicMissionTemplateId = Org_Specific_Setting__mdt.getInstance('NewPublicMissionTemplateId')?.Value_Text__c;
        String newSpecialMissionTemplateId = Org_Specific_Setting__mdt.getInstance('NewSpecialMissionTemplateId')?.Value_Text__c;

        Set<Superhero_Mission__c> publicMissionSet = new Set<Superhero_Mission__c>();
        Set<Superhero_Mission__c> guildSet = new Set<Superhero_Mission__c>();
        Set<Id> guildsIdSet = new Set<Id>();
        for(Superhero_Mission__c mission : newMissionList) {
            if(mission.Is_Public__c) {
                publicMissionSet.add(mission);
            } else {
                if(mission.Guild__c != null) {
                    guildsIdSet.add(mission.Guild__c);
                    guildSet.add(mission);
                }
            }
        }
        if(!publicMissionSet.isEmpty()) {
            Database.executeBatch(new EmailMissionBatch(
                QUERY_LIST.get('NEW_MISSION_ALL'),
                newPublicMissionTemplateId,
                'Contact__c',
                publicMissionSet
                ), Limits.getLimitEmailInvocations()
            );
        }
        if(!guildsIdSet.isEmpty()) {
            Database.executeBatch(new EmailMissionBatch(
                QUERY_LIST.get('NEW_MISSION_GUILD').replace('GUILD_ID_SET', MissionAssignmentTriggerHandler.prepareStringList(guildsIdSet)),
                newSpecialMissionTemplateId,
                'Contact__c',
                guildSet
                ), Limits.getLimitEmailInvocations()
            );
        }
    }
}