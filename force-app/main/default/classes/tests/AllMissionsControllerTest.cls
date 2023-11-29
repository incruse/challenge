@IsTest
private class AllMissionsControllerTest {
    @TestSetup
    static void testSetup() {
        TestDataFactory.createData();

        User customerUser = TestDataFactory.createCommunityUser();
        insert customerUser;
    }

    @IsTest
    static void getMainDatePositiveTest() {
        User customerUser = [SELECT Id FROM User WHERE Profile.UserLicense.Name = 'Customer Community' LIMIT 1];
        AllMissionsController.MissionWrapper result;
        Test.startTest();
            System.runAs(customerUser) {
                result = AllMissionsController.getAllMissions(null);
            }
        Test.stopTest();
        Assert.isNotNull(result);
        Assert.areEqual(1, result.assignmentList.size());
        Assert.areEqual(30, result.missionList.size());
        Assert.isNotNull(result.Hero);
    }

    @IsTest
    static void getMainDateNegativeTest() {
        User customerUser = [SELECT Id FROM User WHERE Profile.UserLicense.Name = 'Salesforce' LIMIT 1];
        AllMissionsController.MissionWrapper result;
        Test.startTest();
        System.runAs(customerUser) {
            try{
                result = AllMissionsController.getAllMissions(null);
                Assert.isNull(result);
            } catch (Exception ex) {
                Assert.areEqual(ex.getMessage(), System.Label.No_Access_to_the_site);
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void acceptMissionPositiveTest() {
        delete [SELECT Id FROM Mission_Assignment__c];
        User customerUser = [SELECT Id, ContactId FROM User WHERE Profile.UserLicense.Name = 'Customer Community' LIMIT 1];
        Mission_Assignment__c result;
        Hero__c hero = [SELECT Id, Contact__c FROM Hero__c LIMIT 1];
        hero.Contact__c = customerUser.ContactId;
        update hero;

        Superhero_Mission__c mission = [SELECT Id FROM Superhero_Mission__c LIMIT 1];
        Test.startTest();
        System.runAs(customerUser) {
            result = AllMissionsController.acceptMission(mission, hero);
        }
        Test.stopTest();
        Assert.isNotNull(result);
        Assert.areEqual(result.Mission__c, mission.Id);
        Assert.areEqual(result.Hero__c, hero.Id);
    }

    @IsTest
    static void acceptMissionNegativeTest() {
        delete [SELECT Id FROM Mission_Assignment__c];
        User customerUser = [SELECT Id, ContactId FROM User WHERE Profile.UserLicense.Name = 'Customer Community' LIMIT 1];
        Mission_Assignment__c result;
        Hero__c hero = [SELECT Id, Contact__c FROM Hero__c LIMIT 1];
        hero.Contact__c = customerUser.ContactId;
        update hero;

        Test.startTest();
        try {
            System.runAs(customerUser) {
                result = AllMissionsController.acceptMission(null, hero);
                Assert.isNull(result);
            }
        } catch (Exception ex) {
            Assert.areEqual(ex.getMessage(), 'Attempt to de-reference a null object');
        }
        Test.stopTest();
    }

    @IsTest
    static void getActiveMissionsPositiveTest() {
        User customerUser = [SELECT Id, ContactId FROM User WHERE Profile.UserLicense.Name = 'Customer Community' LIMIT 1];
        Hero__c hero = [SELECT Id, Contact__c FROM Hero__c LIMIT 1];
        hero.Contact__c = customerUser.ContactId;
        update hero;

        Integer expectedResult = (Integer) [SELECT COUNT(Id)
                                            FROM Mission_Assignment__c
                                            WHERE Hero__c =: hero.Id
                                            AND Status__c =: 'In Progress'][0].get('expr0');
        Integer actualResult;
        Test.startTest();
        System.runAs(customerUser) {
            actualResult = AllMissionsController.getActiveMissions();
        }
        Test.stopTest();
        Assert.areEqual(expectedResult, actualResult);
    }

    @IsTest
    static void updateAssignmentsPositiveTest() {
        User customerUser = [SELECT Id, ContactId
                             FROM User
                             WHERE Profile.UserLicense.Name = 'Customer Community'
                             LIMIT 1];
        Hero__c hero = [SELECT Id, Contact__c FROM Hero__c LIMIT 1];
        hero.Contact__c = customerUser.ContactId;
        update hero;

        Mission_Assignment__c assignment = [SELECT Id, Status__c
                                            FROM Mission_Assignment__c
                                            WHERE Hero__c =: hero.Id
                                            AND Status__c =: 'In Progress' LIMIT 1];
        Mission_Assignment__c actualResult;
        Test.startTest();
        System.runAs(customerUser) {
            actualResult = AllMissionsController.completeMission(assignment);
        }
        Test.stopTest();
        Assert.areEqual(actualResult.Status__c, 'Completed');
    }
}