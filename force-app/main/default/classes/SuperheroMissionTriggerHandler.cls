public with sharing class SuperheroMissionTriggerHandler {
    private final Boolean triggerIsExecuting;
    private final Integer triggerSize;
    private static final Map<String, String> QUERY_LIST = new Map<String, String>{
            'NEW_MISSION_ALL' => 'SELECT Id, Contact__c FROM Hero__c',
            'NEW_MISSION_GUILD' => 'SELECT Id, Contact__c FROM Hero__c WHERE Guild__c IN GUILD_ID_SET'
    };
    public SuperheroMissionTriggerHandler(Boolean triggerIsExecuting, Integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
    }
    public void beforeUpdate(List<Superhero_Mission__c> newMissionList, List<Superhero_Mission__c> oldMissionList, Map<Id, Superhero_Mission__c> oldMissionMap, Map<Id, Superhero_Mission__c> newMissionMap) {
    }
    public void afterInsert(List<Superhero_Mission__c> newMissionList, Map<Id, Superhero_Mission__c> newMissionMap) {
        newMissionNotification(newMissionList);
    }
    public void afterUpdate(List<Superhero_Mission__c> newMissionList, List<Superhero_Mission__c> oldMissionList, Map<Id, Superhero_Mission__c> oldMissionMap, Map<Id, Superhero_Mission__c> newMissionMap) {
    }

    public static void newMissionNotification(List<Superhero_Mission__c> newMissionList) {
        String newPublicMissionTemplateId = Org_Specific_Setting__mdt.getInstance('NewPublicMissionTemplateId')?.Value_Text__c;
        String newSpecialMissionTemplateId = Org_Specific_Setting__mdt.getInstance('NewSpecialMissionTemplateId')?.Value_Text__c;

        Set<Id> publicMissionSet = new Set<Id>();
        Set<Id> guildsIdSet = new Set<Id>();
        for(Superhero_Mission__c mission : newMissionList) {
            if(mission.Is_Public__c) {
                publicMissionSet.add(mission.Id);
            }
            if(mission.Guild__c != null) {
                guildsIdSet.add(mission.Guild__c);
            }
        }
        if(!publicMissionSet.isEmpty()) {
            Database.executeBatch(new EmailMissionBatch(
                QUERY_LIST.get('NEW_MISSION_ALL'),
                newPublicMissionTemplateId,
                    null,
                'Contact__c')
            );
        }
        if(!guildsIdSet.isEmpty()) {
            Database.executeBatch(new EmailMissionBatch(
                QUERY_LIST.get('NEW_MISSION_GUILD').replace('GUILD_ID_SET', MissionAssignmentTriggerHandler.prepareStringList(guildsIdSet)),
                newSpecialMissionTemplateId,
                'Contact__c')
            );
        }
    }
}