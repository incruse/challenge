@IsTest
private class EmailMissionBatchTest {
    @TestSetup
    static void testSetup() {
        TestDataFactory.createData();
        User customerUser = TestDataFactory.createCommunityUser();
        insert customerUser;
    }

    @IsTest
    static void newPublicMissionPositiveTest() {
        User customerUser = [SELECT Id FROM User WHERE Profile.UserLicense.Name = 'Customer Community' LIMIT 1];
        Test.startTest();
        System.runAs(customerUser) {
            Database.executeBatch(new EmailMissionBatch(
                    'NEW_PUBLIC_MISSION', new Set<Superhero_Mission__c>([SELECT Id FROM Superhero_Mission__c LIMIT 1])
            ), 1
            );
        }
        Test.stopTest();
        Assert.isTrue(Limits.getEmailInvocations() == 0);
        for(AsyncApexJob job : [SELECT Id, MethodName, Status FROM AsyncApexJob]) {
            Assert.areEqual(job.Status, 'Completed');
        }
    }

    @IsTest
    static void newSpecialMissionPositiveTest() {
        User customerUser = [SELECT Id FROM User WHERE Profile.UserLicense.Name = 'Customer Community' LIMIT 1];
        Test.startTest();
        System.runAs(customerUser) {
            Database.executeBatch(new EmailMissionBatch(
                    'NEW_SPECIAL_MISSION', new Set<Superhero_Mission__c>([SELECT Id, Guild__c FROM Superhero_Mission__c LIMIT 1])
            ), 1
            );
        }
        Test.stopTest();
        Assert.isTrue(Limits.getEmailInvocations() == 0);
        for(AsyncApexJob job : [SELECT Id, MethodName, Status FROM AsyncApexJob]) {
            Assert.areEqual(job.Status, 'Completed');
        }
    }

    @IsTest
    static void completeMissionPositiveTest() {
        User customerUser = [SELECT Id FROM User WHERE Profile.UserLicense.Name = 'Customer Community' LIMIT 1];
        Test.startTest();
        System.runAs(customerUser) {
            Database.executeBatch(new EmailMissionBatch(
                    'COMPLETED_THE_MISSION', new Set<Mission_Assignment__c>([SELECT Id, Mission__c FROM Mission_Assignment__c LIMIT 1])
            ), 1
            );
        }
        Test.stopTest();
        Assert.isTrue(Limits.getEmailInvocations() == 0);
        for(AsyncApexJob job : [SELECT Id, MethodName, Status FROM AsyncApexJob]) {
            Assert.areEqual(job.Status, 'Completed');
        }
    }

    @IsTest
    static void failedMissionPositiveTest() {
        User customerUser = [SELECT Id FROM User WHERE Profile.UserLicense.Name = 'Customer Community' LIMIT 1];
        delete [SELECT Id FROM Mission_Assignment__c WHERE Status__c = 'Failed'];
        Test.startTest();
        System.runAs(customerUser) {
            Database.executeBatch(new EmailMissionBatch(
                    'FAILED_THE_MISSION', new Set<Mission_Assignment__c>([SELECT Id, Mission__c FROM Mission_Assignment__c LIMIT 1])
            ), 1
            );
        }
        Test.stopTest();
        List<Mission_Assignment__c> failedMissions = [SELECT Id FROM Mission_Assignment__c WHERE Status__c = 'Failed'];
        Assert.isTrue(Limits.getEmailInvocations() == 0);
        Assert.isTrue(failedMissions.size() == 1);
        for(AsyncApexJob job : [SELECT Id, MethodName, Status FROM AsyncApexJob]) {
            Assert.areEqual(job.Status, 'Completed');
        }
    }
}