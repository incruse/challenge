({

    getRecords: function (component) {
        var action = component.get('c.getAllMissions');
        var offSet = component.get('v.offSet');
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var labels = component.get('v.labels');
        action.setParams({
            'offSet' : offSet
        });
        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === "SUCCESS"){
                let result = response.getReturnValue();
                result.missionList.forEach(el => {
                    let completed = false;
                    let inProgress = false;
                    let available = false;
                    let failed = false;
                    if(el.hasOwnProperty('Mission_Assignments__r')) {
                        el.Mission_Assignments__r.forEach(ma => {
                            if(ma.Hero__r.Contact__r.OwnerId === userId) {
                                el.Status = ma.Status__c;
                                inProgress = ma.Status__c === labels.IN_PROGRESS;
                                completed = ma.Status__c === labels.COMPLETED;
                                failed = ma.Status__c === labels.FAILED;
                                available = false;
                            }
                        })
                    }
                    if(!el.Status) {
                        el.Status = labels.AVAILABLE;
                    }
                    el.isSelected = false;
                });
                component.set('v.missions', result.missionList);
                component.set('v.hero', result.Hero);
            } else {
                console.error(response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    selectLine: function(component, event, helper) {
        var missionId = event.currentTarget.dataset.mission;
        this.selectHandler(missionId, component);
    },

    selectHandler: function(missionId, component) {
        var missions = component.get('v.missions');
        var missionDiv = document.getElementById(missionId);
        if (missionDiv) {
            missions.forEach(el => {
                el.isSelected = el.Id === missionId ? !el.isSelected : false;
            });
            component.set('v.missions', missions);
        } else {
            console.error('Mission component not found.');
        }
    },

    pushSelectedEvent: function (component, element) {
        component.find('missionDetailsChannel').publish({mission : element, type : 'INIT', hero : component.get('v.hero')});
    },

});