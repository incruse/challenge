import {track, LightningElement, wire} from 'lwc';
import { subscribe, publish, unsubscribe, MessageContext } from 'lightning/messageService';
import MISSION_DETAILS_CHANNEL from '@salesforce/messageChannel/Mission_Details__c';
import USER_ID from '@salesforce/user/Id';
import acceptMission from '@salesforce/apex/AllMissionsController.acceptMission';
import completeMission from '@salesforce/apex/AllMissionsController.completeMission';
import getActiveMissions from '@salesforce/apex/AllMissionsController.getActiveMissions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import MISSION_DETAILS_LABEL from '@salesforce/label/c.Mission_Details';
import ASSASSINS_LABEL from '@salesforce/label/c.Assassins';
import ACCEPT_LABEL from '@salesforce/label/c.Accept';
import COMPLETE_LABEL from '@salesforce/label/c.Complete';
import NO_SELECTED_MESSAGE from '@salesforce/label/c.No_Selected_Message';
import IN_PROGRESS_LABEL from '@salesforce/label/c.In_Progress';
import AVAILABLE_LABEL from '@salesforce/label/c.Available';
import COMPLETED_LABEL from '@salesforce/label/c.Completed';
import S_CREATE_MESSAGE from '@salesforce/label/c.Create_New_Assignment_Message';
import S_COMPLETED_MESSAGE from '@salesforce/label/c.Completed_Assignment_Message';
import W_LOW_RANK_MESSAGE from '@salesforce/label/c.Low_Rank_Warning_Message';
import LIMIT_ACTIVE_MISSION_MESSAGE from '@salesforce/label/c.Limit_Active_Mission_Message';

export default class MissionDetail extends LightningElement {
    labels = {
        MISSION_DETAILS : MISSION_DETAILS_LABEL,
        ASSASSINS : ASSASSINS_LABEL,
        ACCEPT : ACCEPT_LABEL,
        COMPLETE : COMPLETE_LABEL,
        NO_SELECTED : NO_SELECTED_MESSAGE,
        AVAILABLE : AVAILABLE_LABEL,
        IN_PROGRESS : IN_PROGRESS_LABEL,
        COMPLETED : COMPLETED_LABEL,
        S_CREATE_MSG : S_CREATE_MESSAGE,
        S_COMPLETED_MSG : S_COMPLETED_MESSAGE,
        W_LOW_RANK_MSG : W_LOW_RANK_MESSAGE,
        LIMIT_RANK_MSG : LIMIT_ACTIVE_MISSION_MESSAGE
    }

    userId = USER_ID;
    isLoading = true;
    ranksGradation = ['A', 'B', 'C', 'D', 'S'];
    hero;

    get buttonLabel() {
        return this.mission.Status !== this.labels.IN_PROGRESS ? this.labels.ACCEPT : this.labels.COMPLETED;
    }

    @track mission = {};
    @track isSelected = false;
    pushMission(type) {
        const payload = {
            mission : this.mission,
            type : type,
            hero : this.hero
        };

        publish(this.messageContext, MISSION_DETAILS_CHANNEL, payload);
    }

    get showButton() {
        return [this.labels.AVAILABLE, this.labels.IN_PROGRESS].includes(this.mission.Status);
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    subscription = null;

    @wire(MessageContext)
    messageContext;
    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            MISSION_DETAILS_CHANNEL,
            (message) => this.handleMessage(message)
        );
        this.isLoading = false;
    }
    handleMessage(message) {
        if(message.type !== 'INIT') {
            return;
        }
        let mission = JSON.parse(JSON.stringify(message.mission));
        mission.Reward = this.formatCurrency(message.mission.Reward__c);
        this.mission = mission;
        this.hero = message.hero;
        this.isSelected = message.mission.isSelected;
    }
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    formatCurrency(value) {
        const formatter = new Intl.NumberFormat(navigator.language, {
            style: 'currency',
            currency: 'USD',
        });
        return formatter.format(value);
    }

    async buttonHandler() {
        this.isLoading = true;
        if(this.buttonLabel === this.labels.ACCEPT) {
            if(!this.checkRank()) {
                let missionLevel = this.ranksGradation.indexOf(this.mission.Complexity_Rank__c);
                this.showToast('', this.labels.W_LOW_RANK_MSG
                    .replace('{0}', this.ranksGradation.slice(missionLevel === 0 ? 0 : missionLevel -1, missionLevel + 2).toString())
                    .replace('{1}', this.hero.Rank__c), 'warning');
                return;
            }
            let activeMission = await getActiveMissions();
            if(activeMission >= 3) {
                this.showToast('', this.labels.LIMIT_RANK_MSG.replace('{0}', activeMission), 'warning');
                return;
            }
            acceptMission({mission : this.mission, hero : this.hero})
                .then(result => {
                    if(result) {
                        let mission = JSON.parse(JSON.stringify(this.mission));
                        mission.Status = this.labels.IN_PROGRESS;
                        this.mission = mission;
                        this.updateMissionAssignment(result, this.labels.S_CREATE_MSG, 'CREATE');
                    }
                })
                .catch(error => {
                    this.showToast('', error.body.message, 'error');
                    console.error(error);
                })
                .finally(() => this.isLoading = false)
        } else if (this.buttonLabel === this.labels.COMPLETED) {
            let assignment = this.mission.Mission_Assignments__r.find(obj => obj.Hero__c === this.hero.Id);
            console.log(JSON.parse(JSON.stringify(this.mission.Mission_Assignments__r)));
            if(!assignment) {
                return;
            }
            completeMission({assignment : assignment})
                .then(result => {
                    console.log('error');
                    let mission = JSON.parse(JSON.stringify(this.mission));
                    mission.Status = this.labels.COMPLETED;
                    this.mission = mission;
                    this.updateMissionAssignment(result, this.labels.S_COMPLETED_MSG, 'UPDATE');
                    this.isSelected = true;
                })
                .catch(error => {
                    this.showToast('', error.body.message, 'error');
                })
                .finally(() => this.isLoading = false)
        } else {
            this.isLoading = false;
        }
    }

    updateMissionAssignment(assignments, message, type) {
        let mission = JSON.parse(JSON.stringify(this.mission));
        if(mission.hasOwnProperty('Mission_Assignments__r')) {
            mission.Mission_Assignments__r.push(assignments);
        } else {
            mission.Mission_Assignments__r = new Array(assignments);
        }
        this.mission = mission;
        this.showToast('SUCCESS', message, 'success');
        this.pushMission(type);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            variant: variant,
            title: title,
            message: message
        }))
        this.isLoading = false;
    }

    checkRank() {
        let missionRank = this.mission.Complexity_Rank__c;
        let heroRank = this.ranksGradation.indexOf(this.hero.Rank__c);
        let heroRange = this.ranksGradation.slice(heroRank === 0 ? 0 : heroRank - 1, heroRank + 2);
        console.log(heroRange.includes(missionRank));
        console.log(heroRange);

        return heroRange.includes(missionRank);
    }
}