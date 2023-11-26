@IsTest
public class TestDataFactory {
    public static void createData() {
        List<Account> accList = createAccount(200);
        insert accList;

        List<Contact> conList = new List<Contact>();
        for(Account acc : accList) {
            conList.addAll(createContact(20, acc.Id));
        }
        insert conList;

        List<User> communityUsers = new List<User>();

        List<Guild__c> guilds = createGuild(100);
        for(Guild__c guild : guilds) {

        }


//        insert createMission(50, true, );
    }

    public static List<Account> createAccount(Integer count) {
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i
            );
            accList.add(acc);
        }
        return accList;
    }

    public static List<Contact> createContact(Integer count, Id accId) {
        List<Contact> contactList = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            Contact con = new Contact(
                    LastName = 'Test Contact ' + i,
                    AccountId = accId,
                    Email = 'testEmail@dev.com'
            );
            contactList.add(con);
        }
        return contactList;
    }

    public static List<User> createCommunityUser(Integer count) {
        List<User> UserList = new List<User>();
        for (Integer i = 0; i < count; i++) {
            User acc = new User(
                Username = 'Test User ' + i
            );
            UserList.add(acc);
        }
        return UserList;
    }

    public static List<Superhero_Mission__c> createMission(Integer count, Boolean isPublic, Id guildId, String rank) {
        List<Superhero_Mission__c> missions = new List<Superhero_Mission__c>();
        for (Integer i = 0; i < count; i++) {
            Superhero_Mission__c mission = new Superhero_Mission__c(
                    Is_Public__c = isPublic,
                    Guild__c = guildId,
                    Reward__c = Math.round(Math.random() * (10000 - 1000) + 1000),
                    Complexity_Rank__c = rank,
                    Details__c = 'Mission Details ' + i,
                    Deadline__c = Date.today().addDays(20).addDays(i)
            );
            missions.add(mission);
        }
        return missions;
    }

    public static List<Guild__c> createGuild(Integer count) {
        List<Guild__c> guilds = new List<Guild__c>();
        for (Integer i = 0; i < count; i++) {
            Guild__c guild = new Guild__c(
                    Name = 'Test Guild ' + i,
                    Vision__c = 'Test Vision ' + i
            );
            guilds.add(guild);
        }
        return guilds;
    }

    public static List<Hero__c> createHero(List<Contact> contacts, String rank, List<Guild__c> guilds) {
        List<Hero__c> heroes = new List<Hero__c>();
        for(Contact con : contacts) {
            for(Guild__c guild : guilds) {
                heroes.add(new Hero__c(
                        Name = con.LastName,
                        Rank__c = rank,
                        Guild__c = guild.Id,
                        Contact__c = con.Id
                ));
            }
        }
        return heroes;
    }

    public static List<Mission_Assignment__c> createMissionAssignment(Map<Superhero_Mission__c, List<Hero__c>> missionsMap) {
        List<Mission_Assignment__c> maList = new List<Mission_Assignment__c>();
        for (Superhero_Mission__c mission : missionsMap.keySet()) {
            for(Hero__c hero : missionsMap.get(mission)) {
                Mission_Assignment__c ma = new Mission_Assignment__c(
                    Mission__c = mission.Id,
                    Hero__c = hero.Id
                );
                maList.add(ma);
            }
        }
        return maList;
    }
}