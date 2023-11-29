@IsTest
private class SuperheroMissionTriggerTest {
    @TestSetup
    static void testSetup() {
        TestDataFactory.createData();
    }

    @IsTest
    static void createPublicMission(){
        delete [SELECT Id FROM Superhero_Mission__c];
        Guild__c guild = [SELECT Id FROM Guild__c LIMIT 1];

        Test.startTest();
            insert TestDataFactory.createMission(1,true,guild.Id, 'A');
        Test.stopTest();

        Superhero_Mission__c mission = [SELECT Id FROM Superhero_Mission__c];
        Assert.isNotNull(mission);
        Assert.isTrue(Limits.getEmailInvocations() == 0);
        for(AsyncApexJob job : [SELECT Id, MethodName, Status FROM AsyncApexJob]) {
            Assert.areEqual(job.Status, 'Completed');
        }
    }

    @IsTest
    static void createSpecialMission(){
        delete [SELECT Id FROM Superhero_Mission__c];
        Contact con = [SELECT Id, LastName FROM Contact LIMIT 1];
        Guild__c guild = [SELECT Id FROM Guild__c LIMIT 1];
        delete [SELECT Id FROM Mission_Assignment__c];
        delete [SELECT Id FROM Hero__c WHERE Guild__c = :guild.Id];

        insert TestDataFactory.createHero(new List<Contact>{con}, 'A',new List<Guild__c>{guild});

        Test.startTest();
            insert TestDataFactory.createMission(1,false,guild.Id, 'B');
        Test.stopTest();

        Superhero_Mission__c mission = [SELECT Id FROM Superhero_Mission__c];
        Assert.isNotNull(mission);
        Assert.isTrue(Limits.getEmailInvocations() == 0);
        for(AsyncApexJob job : [SELECT Id, MethodName, Status FROM AsyncApexJob]) {
            Assert.areEqual(job.Status, 'Completed');
        }
    }
}