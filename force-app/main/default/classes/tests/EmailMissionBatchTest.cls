@IsTest
private class EmailMissionBatchTest {
    private static List<String> QUERY_LIST = new List<String>{
            'SELECT Id, Status__c, Hero__r.Contact__c, Mission__c, Mission__r.Reward__c FROM Mission_Assignment__c WHERE Mission__c IN MISSIONS AND Id NOT IN ID_SET LIMIT 1',
            'SELECT Id, Contact__c FROM Hero__c',
            'SELECT Id, Contact__c, Guild__c, Guild__r.Name FROM Hero__c WHERE Guild__c IN GUILD_ID_SET'
    };

    @TestSetup
    static void testSetup() {
        TestDataFactory.createData();
        User customerUser = TestDataFactory.createCommunityUser();
        insert customerUser;
    }

    @IsTest
    static void EmailMissionBatchPossitiveTest() {
        User customerUser = [SELECT Id FROM User WHERE Profile.UserLicense.Name = 'Customer Community' LIMIT 1];
        EmailTemplate newMissionTemplate = [SELECT Id FROM EmailTemplate WHERE Name = 'Complete the Mission'];
        Set<Id> winnerIdList = new Set<Id>();
        Set<Id> missionIdSet = new Set<Id>();
        List<Mission_Assignment__c> missionAssigment = new List<Mission_Assignment__c>();
        for(Mission_Assignment__c mission : [SELECT Id, Status__c, Mission__c FROM Mission_Assignment__c]) {
            mission.Status__c = 'Completed';
            missionAssigment.add(mission);
            winnerIdList.add(mission.Id);
            missionIdSet.add(mission.Mission__c);
        }

        Test.startTest();
        System.runAs(customerUser) {
            Database.executeBatch(new EmailMissionBatch(
                QUERY_LIST[0]
                        .replace('ID_SET', MissionAssignmentTriggerHandler.prepareStringList(new Set<Id>{missionAssigment[0].Id}))
                        .replace('MISSIONS', MissionAssignmentTriggerHandler.prepareStringList(missionIdSet)),
                newMissionTemplate.Id,
                'Hero__r.Contact__c',
                missionIdSet
            ), 1
            );
            Assert.isTrue(Limits.getEmailInvocations() == 0);

        }
        Test.stopTest();
        Assert.isTrue(Limits.getEmailInvocations() == 0);
        for(AsyncApexJob job : [SELECT Id, MethodName, Status FROM AsyncApexJob]) {
            Assert.areEqual(job.Status, 'Completed');
        }
    }
}