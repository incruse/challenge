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
            } catch (Exception ex) {
                Assert.areEqual(ex.getMessage(), System.Label.No_Access_to_the_site);
            }
        }
    }
}