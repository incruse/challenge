public with sharing class SuperheroMissionTriggerHandler {
    public static void afterInsert(List<Superhero_Mission__c> newMissionList, Map<Id, Superhero_Mission__c> newMissionMap) {
        newMissionNotification(newMissionList);
    }

    public static void newMissionNotification(List<Superhero_Mission__c> newMissionList) {
        Set<Superhero_Mission__c> publicMissionSet = new Set<Superhero_Mission__c>();
        Set<Superhero_Mission__c> guildSet = new Set<Superhero_Mission__c>();
        for(Superhero_Mission__c mission : newMissionList) {
            if(mission.Is_Public__c) {
                publicMissionSet.add(mission);
            } else {
                if(mission.Guild__c != null) {
                    guildSet.add(mission);
                }
            }
        }
        if(!publicMissionSet.isEmpty() && !Test.isRunningTest()) {
            Database.executeBatch(new EmailMissionBatch(
                    'NEW_PUBLIC_MISSION',
                    publicMissionSet
            ), Limits.getLimitEmailInvocations()
            );
        }
        if(!guildSet.isEmpty() && !Test.isRunningTest()) {
            Database.executeBatch(new EmailMissionBatch(
                    'NEW_SPECIAL_MISSION',
                    guildSet
            ), Limits.getLimitEmailInvocations()
            );
        }
    }
}