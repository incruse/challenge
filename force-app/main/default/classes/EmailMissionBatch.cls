public without sharing class EmailMissionBatch implements Database.Batchable<SObject>, Database.Stateful {
    public String QUERY_STRING;
    public String EMAIL_TEMPLATE;
    public String RECIPIENT_ID_FIELD;
    public Set<Id> MISSIONS;
    public Map<String, String> FIELD_VALUES_MAP;

    public EmailMissionBatch(String query, String emailTemplateId, Map<String, String> fieldsValueMap, String recipientIdField, Set<Id> missionSet) {
        RECIPIENT_ID_FIELD = recipientIdField;
        MISSIONS = missionSet;
        EMAIL_TEMPLATE = emailTemplateId;
        QUERY_STRING = query;
        FIELD_VALUES_MAP = fieldsValueMap;
    }

    public EmailMissionBatch(String query, String emailTemplateId, String recipientIdField, Set<Id> missionSet) {
        RECIPIENT_ID_FIELD = recipientIdField;
        MISSIONS = missionSet;
        EMAIL_TEMPLATE = emailTemplateId;
        QUERY_STRING = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            QUERY_STRING
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
                for(Id mission : MISSIONS) {
                    if(RECIPIENT_ID_FIELD.contains('__r')) {
                        emailRecipientRecordMap.put(so.getSObject(RECIPIENT_ID_FIELD.substringBefore('.')).get(RECIPIENT_ID_FIELD.substringAfter('.')).toString(), mission);
                    } else {
                        emailRecipientRecordMap.put(so.get(RECIPIENT_ID_FIELD).toString(), mission);
                    }
                }
            }
            if (!recordToUpdate.isEmpty()) {
                update scope;
            }
            if (!emailRecipientRecordMap.isEmpty()) {
                getSendEmailResults(emailRecipientRecordMap, EMAIL_TEMPLATE);
            }
        } catch (Exception ex) {
            throw new IllegalArgumentException(ex.getMessage());
        }
    }
    private static List<Messaging.SendEmailResult> getSendEmailResults(Map<Id, Id> emailRecipientRecordMap, String emailTemplateId) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Id recipient : emailRecipientRecordMap.keySet()) {
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateId, null, emailRecipientRecordMap.get(recipient));
            mail.setTargetObjectId(recipient);
            mail.setSaveAsActivity(false);
            emails.add(mail);
        }

        return Messaging.sendEmail(emails);
    }

    public static Object castStringToFieldType(Schema.DisplayType fieldType, String stringValue) {
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
            when PERCENT {
                return Double.valueOf(stringValue);
            }
            when STRING {
                return stringValue;
            }
            when ID {
                return stringValue;
            }
        }
        return null;
    }

    public void finish(Database.BatchableContext bc) {
    }
}