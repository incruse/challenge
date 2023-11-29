({
    doInit: function(component, event, helper) {
        helper.getRecords(component);
    },

    selectLineHandler: function (component, event, helper) {
        helper.selectLine(component, event, helper);
        helper.pushSelectedEvent(component, component.get('v.missions').find( mission => mission.Id === event.currentTarget.dataset.mission));
    },

    updateMissionHandler: function (component, event, helper) {
        if(event.getParam('type') === 'INIT') {
            return;
        }
        const mission = event.getParam("mission");
        var missions = JSON.parse(JSON.stringify(component.get('v.missions')));
        missions.forEach(el => {
            if(el.Id === mission.Id) {
                el.Mission_Assignments__r = mission.Mission_Assignments__r;
                el.Status = mission.Status;
                el.isSelected = true;
            }
        })
        var missionDiv = document.getElementById(mission.Id);
        if (missionDiv) {
            component.set('v.missions', null);
            component.set('v.missions', missions);
        } else {
            console.error('Mission component not found.');
        }
        helper.pushSelectedEvent(component, mission);
    }

});