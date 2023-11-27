public with sharing class AllMissionsController {
    private static final AllMissionsControllerHelper helper = new AllMissionsControllerHelper();

    @AuraEnabled(Cacheable=false)
    public static MissionWrapper getAllMissions(Integer offSet) {
        try{
            return helper.getAllMissions(offSet);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Mission_Assignment__c acceptMission(Superhero_Mission__c mission, Hero__c hero) {
        try{
            return helper.acceptMission(mission, hero);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Integer getActiveMissions() {
        try{
            return helper.getActiveMissions();
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<Mission_Assignment__c> completeMission(Mission_Assignment__c assignment) {
        try{
            return helper.updateAssignments(assignment);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class MissionWrapper {
        @AuraEnabled
        public List<Mission_Assignment__c> assignmentList {get;set;}

        @AuraEnabled
        public List<Superhero_Mission__c> missionList {get;set;}

        @AuraEnabled
        public Hero__c Hero {get;set;}
    }

    private without sharing class AllMissionsControllerHelper {
        private final Boolean isCommunityUser;
        private final String USER_ID = UserInfo.getUserId();
        private String HERO_ID;
        private final String COMPLETED_STATUS = System.Label.Completed;
        private final String IN_PROGRESS_STATUS = System.Label.In_Progress;
        private final String NO_GUILD_MESSAGE = System.Label.No_Guild_Error_Message;
        private final String NO_ACCESS_MESSAGE = System.Label.No_Access_to_the_site;

        AllMissionsControllerHelper() {
            User currentUser = [SELECT Id, ContactId FROM User WHERE Id =: USER_ID LIMIT 1];
            isCommunityUser = currentUser.ContactId != null;
            Hero__c hero = [SELECT Id FROM Hero__c WHERE Contact__c =: currentUser.ContactId LIMIT 1];
            if(isCommunityUser && hero != null) {
                HERO_ID = hero.Id;
            } else {
                throw new IllegalArgumentException(NO_ACCESS_MESSAGE);
            }
        }

        public Integer getActiveMissions() {
            return (Integer) [SELECT COUNT(Id)
                              FROM Mission_Assignment__c
                              WHERE Hero__c =: HERO_ID
                              AND Status__c =: IN_PROGRESS_STATUS][0].get('expr0');
        }

        public Mission_Assignment__c acceptMission(Superhero_Mission__c mission, Hero__c hero) {
            Mission_Assignment__c assignment = new Mission_Assignment__c(
                Hero__c = hero.Id,
                Mission__c = mission.Id
            );

            insert assignment;
            return getMissionAssignmentSQOL(assignment.Id);
        }

        public List<Mission_Assignment__c> updateAssignments(Mission_Assignment__c assignment) {
            List<Mission_Assignment__c> recordsToUpdate = new List<Mission_Assignment__c>();
            recordsToUpdate.add(updateAssignment(assignment, COMPLETED_STATUS));
            update recordsToUpdate;
            return recordsToUpdate;
        }

        public Mission_Assignment__c updateAssignment(Mission_Assignment__c assignment, String status) {
            Mission_Assignment__c updatedAssignment = new Mission_Assignment__c(
                Id = assignment.Id,
                Status__c = status
            );
            return updatedAssignment;
        }

        public MissionWrapper getAllMissions(Integer offSet) {
            Hero__c hero = getHero();
            if(String.isBlank(hero.Guild__c)) {
                throw new IllegalArgumentException(NO_GUILD_MESSAGE);
            }
            MissionWrapper result = new MissionWrapper();
            result.assignmentList = getMissionAssignmentSQOL(offSet);
            result.missionList = getSuperheroMissionsSQOL(offSet, hero.Guild__c);
            result.Hero = hero;
            return result;
        }

        private List<Superhero_Mission__c> getSuperheroMissionsSQOL(Integer offSet, String guildId) {
            String query = 'SELECT Id, Complexity_Rank__c, Deadline__c, Is_Public__c, Reward__c, Details__c, Name, Guild__c, Guild__r.Name, Subject__c, ' +
                    '(SELECT Id, Name, Hero__c, Hero__r.Name, Hero__r.Contact__r.Name, Mission__c, Status__c ' +
                    'FROM Mission_Assignments__r WHERE Hero__c =: HERO_ID) ' +
                    'FROM Superhero_Mission__c ' +
                    'WHERE Is_Public__c = true ' +
                    'OR Guild__c =: guildId ' +
                    'ORDER BY CreatedDate DESC ';
            query += offSet != null ? 'LIMIT 50 OFFSET :offSet' : 'LIMIT 50';
            return Database.query(query);
        }

        private Hero__c getHero() {
            return [SELECT Id, Rank__c, Guild__c, Contact__c, Guild__r.Name
                    FROM Hero__c
                    WHERE Id = :HERO_ID
                    LIMIT 1];
        }

        private Mission_Assignment__c getMissionAssignmentSQOL(String assignmentId) {
            return [SELECT Id, Name, Hero__c, Hero__r.Contact__c, Hero__r.Name, Mission__c, Status__c, Mission__r.Name
                    FROM Mission_Assignment__c
                    WHERE Id =: assignmentId
                    LIMIT 1];
        }

        private List<Mission_Assignment__c> getMissionAssignmentSQOL(Integer offSet) {
            String query = 'SELECT Id, Name, Hero__c, Hero__r.Contact__r.OwnerId, Hero__r.Name, Mission__c, Status__c, Mission__r.Name ' +
                    'FROM Mission_Assignment__c ' +
                    'WHERE Hero__c =: HERO_ID';
            query += offSet != null ? ' LIMIT 50 OFFSET :offSet' : ' LIMIT 50';
            return Database.query(query);
        }
    }
}