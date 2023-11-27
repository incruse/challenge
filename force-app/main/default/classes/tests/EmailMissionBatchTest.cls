@IsTest
private class EmailMissionBatchTest {
    @TestSetup
    static void testSetup() {
        TestDataFactory.createData();
    }

    @IsTest
    static void EmailMissionBatchPossitiveTest() {
        User customerUser = [SELECT Id FROM User WHERE Profile.UserLicense.Name = 'Customer Community' LIMIT 1];
        AllMissionsController.MissionWrapper result;
        Test.startTest();
        System.runAs(customerUser) {
            result = AllMissionsController.getAllMissions(null);

        }
//        Database.executeBatch(new EmailMissionBatch(
//                QUERY_LIST[1].replace('ID_SET', prepareStringList(winnerIdList)),
//                completedEmailTemplateId,
//                'Hero__r.Contact__c',
//                new Set<Superhero_Mission__c>(missionSet)
//        )
//        );
    }
}