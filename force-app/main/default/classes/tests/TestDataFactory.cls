@IsTest
public class TestDataFactory {
    public static void createData() {
        List<Account> accList = createAccount(20);
        insert accList;

        List<Contact> conList = new List<Contact>();
        for(Account acc : accList) {
            conList.addAll(createContact(5, acc.Id));
        }
        insert new List<Contact>(conList);

        List<Guild__c> guilds = createGuild(10);
        insert guilds;

        List<Hero__c> heroes = createHero(conList, 'A', guilds);
        insert heroes;

        List<Superhero_Mission__c> missions = createMission(10, true, guilds[0].Id, 'A');
        missions.addAll(createMission(10, true, guilds[1].Id, 'B'));
        missions.addAll(createMission(10, true, guilds[4].Id, 'S'));



        insert missions;

        Map<Superhero_Mission__c, List<Hero__c>> maMap = new Map<Superhero_Mission__c, List<Hero__c>>();
        maMap.put(missions[0], heroes);
        insert createMissionAssignment(maMap);
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

    public static Set<Contact> createContact(Integer count, Id accId) {
        Set<Contact> contactList = new Set<Contact>();
        for (Integer i = 0; i < count; i++) {
            Contact con = new Contact(
                    LastName = 'Test Contact ' + Math.random() + i * Math.random(),
                    AccountId = accId,
                    Email = 'testEmail@dev.com' + Math.random()
            );
            contactList.add(con);
        }
        return contactList;
    }

    public static User createCommunityUser() {
        Profile profile = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Customer Community' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        User user = new User(
            Username = 'test_challenge' + Math.random() + '@test.com',
            FirstName = 'Test-First',
            LastName = 'Test-Last',
            Alias = 'test',
            Email = 'test' + Math.random() + '@test.com',
            CommunityNickname = String.valueOf(Math.random()).substring(0,6),
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = contact.Id
        );
        return user;
    }

    public static List<Superhero_Mission__c> createMission(Integer count, Boolean isPublic, Id guildId, String rank) {
        List<Superhero_Mission__c> missions = new List<Superhero_Mission__c>();
        for (Integer i = 0; i < count; i++) {
            Superhero_Mission__c mission = new Superhero_Mission__c(
                    Is_Public__c = isPublic,
                    Guild__c = guildId,
                    Reward__c = Math.round(Math.random() * (10000 - 1000) + 1000),
                    Complexity_Rank__c = rank,
                    Subject__c = 'Subject Test' + Math.round(Math.random() * (10000 - 1000) + 1000),
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