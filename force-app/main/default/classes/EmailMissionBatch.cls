public without sharing class EmailMissionBatch implements Database.Batchable<SObject>, Database.Stateful {
    private String EMAIL_TEMPLATE;
    private final String ACTION;
    private String RECIPIENT_ID_FIELD;
    public  Set<Superhero_Mission__c> MISSIONS;
    private Set<Id> GUILD_ID_SET = new Set<Id>();
    private Set<Id> WINNER_IDS = new Set<Id>();
    private Set<Mission_Assignment__c> MISSIONS_IDS = new Set<Mission_Assignment__c>();
    public  Map<String, String> FIELD_VALUES_MAP;

    public EmailMissionBatch(String actionString, Set<Superhero_Mission__c> missionSet) {
        MISSIONS = missionSet;
        ACTION = actionString;
    }

    public EmailMissionBatch(String actionString, Set<Mission_Assignment__c> winnerSet) {
        ACTION = actionString;
        MISSIONS_IDS = winnerSet;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            setAction(ACTION)
        );
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            Map<Id, Id> emailRecipientRecordMap = new Map<Id, Id>();
            List<SObject> recordToUpdate = new List<SObject>();
            for (SObject so : scope) {
                if (FIELD_VALUES_MAP != null) {
                    for (String field : FIELD_VALUES_MAP.keySet()) {
                        Schema.DisplayType type = Schema.getGlobalDescribe().get(so.Id.getSobjectType().getDescribe().getName()).getDescribe().fields.getMap().get(field).getDescribe().getType();
                        so.put(field, castStringToFieldType(type, FIELD_VALUES_MAP.get(field)));
                    }
                    recordToUpdate.add(so);
                }
                for(Superhero_Mission__c mission : MISSIONS) {
                    if(RECIPIENT_ID_FIELD.contains('__r')) {
                        emailRecipientRecordMap.put(so.getSObject(RECIPIENT_ID_FIELD.substringBefore('.')).get(RECIPIENT_ID_FIELD.substringAfter('.')).toString(), mission.Id);
                    } else {
                        emailRecipientRecordMap.put(so.get(RECIPIENT_ID_FIELD).toString(), mission.Id);
                    }
                }
            }
            if (!recordToUpdate.isEmpty()) {
                update scope;
            }

            if (!emailRecipientRecordMap.isEmpty()) {
                getSendEmailResults(emailRecipientRecordMap);
            }
        } catch (Exception ex) {
            throw new IllegalArgumentException(ex.getStackTraceString());
        }
    }
    private List<Messaging.SendEmailResult> getSendEmailResults(Map<Id, Id> emailRecipientRecordMap) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Id recipient : emailRecipientRecordMap.keySet()) {
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(EMAIL_TEMPLATE, null, emailRecipientRecordMap.get(recipient));
            mail.setTargetObjectId(recipient);
            mail.setSaveAsActivity(false);
            emails.add(mail);
        }

        return Messaging.sendEmail(emails);
    }

    public Object castStringToFieldType(Schema.DisplayType fieldType, String stringValue) {
        switch on fieldType {
            when BOOLEAN {
                return Boolean.valueOf(stringValue);
            }
            when DATE {
                return Date.valueOf(stringValue);
            }
            when DATETIME {
                return Datetime.valueOf(stringValue);
            }
            when DOUBLE {
                return Double.valueOf(stringValue);
            }
            when INTEGER {
                return Integer.valueOf(stringValue);
            }
            when PICKLIST {
                return stringValue;
            }
        }
        return stringValue;
    }

    public String setAction(String action) {
        switch on action {
            when 'NEW_PUBLIC_MISSION' {
                EMAIL_TEMPLATE = getEmailTemplate('New Public Mission');
                RECIPIENT_ID_FIELD = 'Contact__c';
                return Test.isRunningTest() ? 'SELECT Id, Contact__c FROM Hero__c LIMIT 1' : 'SELECT Id, Contact__c FROM Hero__c';
            }
            when 'NEW_SPECIAL_MISSION' {
                EMAIL_TEMPLATE = getEmailTemplate('New Special Mission');
                for(Superhero_Mission__c mission : MISSIONS) {
                    GUILD_ID_SET.add(mission.Guild__c);
                }
                RECIPIENT_ID_FIELD = 'Contact__c';
                return 'SELECT Id, Contact__c FROM Hero__c WHERE Guild__c IN :GUILD_ID_SET';
            }
            when 'COMPLETED_THE_MISSION' {
                EMAIL_TEMPLATE = getEmailTemplate('Complete the Mission');
                RECIPIENT_ID_FIELD = 'Hero__r.Contact__c';
                Set<Id> missionIdSet = new Set<Id>();
                for(Mission_Assignment__c mission : MISSIONS_IDS) {
                    missionIdSet.add(mission.Mission__c);
                }
                MISSIONS = new Set<Superhero_Mission__c>([SELECT Id FROM Superhero_Mission__c WHERE Id IN : missionIdSet]);
                return 'SELECT Id, Status__c, Hero__r.Contact__c, Mission__c FROM Mission_Assignment__c WHERE Id IN :MISSIONS_IDS';
            }
            when 'FAILED_THE_MISSION' {
                EMAIL_TEMPLATE = getEmailTemplate('Failed the Mission');
                FIELD_VALUES_MAP = new Map<String, String>{'Status__c' => 'Failed'};
                Set<Id> missionIdSet = new Set<Id>();
                for(Mission_Assignment__c mission : MISSIONS_IDS) {
                    GUILD_ID_SET.add(mission.Mission__c);
                    WINNER_IDS.add(mission.Id);
                }
                MISSIONS = new Set<Superhero_Mission__c>([SELECT Id FROM Superhero_Mission__c WHERE Id IN : GUILD_ID_SET]);

                RECIPIENT_ID_FIELD = 'Hero__r.Contact__c';
                return Test.isRunningTest() ? 'SELECT Id, Status__c, Hero__r.Contact__c, Mission__c FROM Mission_Assignment__c WHERE Mission__c IN :GUILD_ID_SET AND Id NOT IN :WINNER_IDS LIMIT 1'
                        : 'SELECT Id, Status__c, Hero__r.Contact__c, Mission__c FROM Mission_Assignment__c WHERE Mission__c IN :GUILD_ID_SET AND Id NOT IN :WINNER_IDS';
            }
        }
        return null;
    }

    private Id getEmailTemplate(String emailName) {
        return [SELECT Id FROM EmailTemplate WHERE Name = : emailName LIMIT 1].Id;
    }

    public void finish(Database.BatchableContext bc) {
    }
}