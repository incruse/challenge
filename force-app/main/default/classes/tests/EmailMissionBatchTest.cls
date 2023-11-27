@IsTest
private class EmailMissionBatchTest {
    @TestSetup
    static void testSetup() {
        TestDataFactory.createData();
    }

    @IsTest
    static void EmailMissionBatchPossitiveTest() {
//        Database.executeBatch(new EmailMissionBatch(
//                QUERY_LIST[1].replace('ID_SET', prepareStringList(winnerIdList)),
//                completedEmailTemplateId,
//                'Hero__r.Contact__c',
//                new Set<Superhero_Mission__c>(missionSet)
//        )
//        );
    }
}