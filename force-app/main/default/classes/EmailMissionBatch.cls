public with sharing class EmailMissionBatch implements Database.Batchable<SObject>, Database.Stateful {
        public static String QUERY_STRING;
        public static final String SENDER_NAME = Org_Specific_Setting__mdt.getInstance('SenderName')?.Value_Text__c;
        public static String EMAIL_TEMPLATE;
        public static String RECIPIENT_ID_FIELD;
        public static Map<String, String> FIELD_VALUES_MAP;

    public EmailMissionBatch(String query, String emailTemplateId, Map<String, String> fieldsValueMap, String recipientIdField) {
        RECIPIENT_ID_FIELD = recipientIdField;
        EMAIL_TEMPLATE = emailTemplateId;
        QUERY_STRING = query;
        FIELD_VALUES_MAP = fieldsValueMap;
    }

    public EmailMissionBatch(String query, String emailTemplateId, String recipientIdField) {
        RECIPIENT_ID_FIELD = recipientIdField;
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
            Set<Id> whatIdSet = new Set<Id>();
            List<Id> recipientIds = new List<Id>();
            List<SObject> recordToUpdate = new List<SObject>();
            for (SObject so : scope) {
                if (FIELD_VALUES_MAP != null) {
                    for (String field : FIELD_VALUES_MAP.keySet()) {
                        Schema.DisplayType type = Schema.getGlobalDescribe().get(so.Id.getSobjectType().getDescribe().getName()).getDescribe().fields.getMap().get(field).getDescribe().getType();
                        so.put(field, castStringToFieldType(type, FIELD_VALUES_MAP.get(field)));
                    }
                    recordToUpdate.add(so);
                }
                whatIdSet.add(so.Id);
                recipientIds.add(so.get(RECIPIENT_ID_FIELD).toString());
            }
            if (!recordToUpdate.isEmpty()) {
                update scope;
            }
            if (whatIdSet.isEmpty()) {
                getSendEmailResults(new Set<Id>(whatIdSet), new Set<Id>(recipientIds), EMAIL_TEMPLATE);
            }
        } catch (Exception ex) {
            throw new IllegalArgumentException(ex.getMessage());
        }
    }

    public static List<Messaging.SendEmailResult> getSendEmailResults(Set<Id> whatIdSet, Set<Id> recipientIds, String emailTemplateId) {
        Messaging.MassEmailMessage mail = new Messaging.MassEmailMessage();
        mail.setTemplateId(emailTemplateId);
        mail.setSenderDisplayName(SENDER_NAME);
        mail.saveAsActivity = false;
        mail.setTargetObjectIds(new List<Id>(recipientIds));
        mail.setWhatIds(new List<Id>(whatIdSet));

        return Messaging.sendEmail(new Messaging.MassEmailMessage[]{
            mail
        });
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