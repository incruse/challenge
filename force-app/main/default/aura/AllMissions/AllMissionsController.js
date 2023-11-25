({
    doInit: function(component, event, helper) {
        var labels = {
            'ALL_MISSIONS' : $A.get('$Label.c.All_Missions'),
            'RANK' : $A.get('$Label.c.Rank'),
            'MISSION' : $A.get('$Label.c.Mission'),
            'STATUS' : $A.get('$Label.c.Status'),
            'GUILD' : $A.get('$Label.c.Guild'),
            'AVAILABLE' : $A.get('$Label.c.Available'),
            'IN_PROGRESS' : $A.get('$Label.c.In_Progress'),
            'COMPLETES' : $A.get('$Label.c.Completed'),
            'FAILED' : $A.get('$Label.c.Failed')
        };
        component.set('v.labels', labels);
        helper.getRecords(component);
    },

    selectLineHandler: function (component, event, helper) {
        var selectedMission = component.get('v.missions').find( mission => mission.Id === event.currentTarget.dataset.mission);
        helper.selectLine(component, event, helper);
        helper.pushSelectedEvent(component, selectedMission);
    },

    updateMissionHandler: function (component, event, helper) {
        if(event.getParam('type') === 'INIT') {
            return;
        }
        console.log(event.getParam('type'));
        const mission = event.getParam("mission");
        var missions = JSON.parse(JSON.stringify(component.get('v.missions')));
        missions.forEach(el => {
            if(el.Id === mission.Id) {
                el.Mission_Assignments__r = mission.Mission_Assignments__r;
            }
        })
        // $A.get('e.force:refreshView').fire();
        // helper.selectHandler(mission.Id, component);
        var missionDiv = document.getElementById(mission.Id);
        if (missionDiv) {
            missions.forEach(el => {
                el.isSelected = el.Id === mission.Id;
            });
            component.set('v.missions', missions);
        } else {
            console.error('Mission component not found.');
        }
        helper.pushSelectedEvent(component, mission);
    }

});