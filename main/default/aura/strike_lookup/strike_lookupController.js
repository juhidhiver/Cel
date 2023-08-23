/*Strike by Appiphony

Version: 1.0.0
Website: http://www.lightningstrike.io
GitHub: https://github.com/appiphony/Strike-Components
License: BSD 3-Clause License*/
({
    onInit: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.onInit ---------------');
        component.handleClick = $A.getCallback(function() {
            if (!component.isValid()) {
                window.removeEventListener('click', component.handleClick);

                return;
            }

            helper.closeMenu(component, event, helper);
        });

        window.addEventListener('click', component.handleClick);

        component.set('v.initCallsRunning', 3);


        helper.getRecentRecords(component, event, helper);
        helper.getRecordByValue(component, event, helper);
        helper.getRecordLabel(component, event, helper);

        var randomNumber = Math.floor(1000 + Math.random() * 9000);

        component.set('v.idNumber', randomNumber);
        
        component.set('v.isMobile', $A.get('$Browser.formFactor') === 'DESKTOP' ? false : true);
    },

    handleInputClick: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleInputClick ---------------');
        event.stopPropagation();
    },

    handleSearchingClick: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleSearchingClick ---------------');
        component.set('v.searching', false);
    },

    handleInputFocus: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleInputFocus ---------------');
        $A.util.addClass(component.find('lookup'), 'sl-lookup--open');
        
        if (component.get('v.disabled')) {
            return;
        }
        var countrySearch = component.get("v.countrySearch");
        console.log('@@@ countrySearch : ' + countrySearch);
        /*if(!countrySearch){
            return;
        }*/
        helper.getRecordsBySearchTerm(component, event, helper);
    },

    cancelLookup: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.cancelLookup ---------------');
        helper.closeMobileLookup(component, event, helper);
    },

    handleInputKeyDown: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleInputKeyDown ---------------');
        if (component.get('v.disabled')) {
            return;
        }

        var KEYCODE_TAB = 9;

        var keyCode = event.which || event.keyCode || 0;

        if (keyCode === KEYCODE_TAB) {
            helper.closeMenu(component, event, helper);
        }
    },

    handleInputKeyPress: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleInputKeyPress ---------------');
        if (component.get('v.disabled')) {
            return;
        }
    },

    handleInputKeyUp: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleInputKeyUp ---------------');
        if (component.get('v.disabled')) {
            return;
        }
        var countrySearch = component.get("v.countrySearch");
        console.log('@@@ countrySearch : ' + countrySearch);
        /*if(!countrySearch){
            return;
        }*/
        var KEYCODE_ENTER = 13;
        var KEYCODE_UP = 38;
        var KEYCODE_DOWN = 40;

        var keyCode = event.which || event.keyCode || 0;

        if (keyCode === KEYCODE_ENTER) {
            helper.updateValueByFocusIndex(component, event, helper);
        } else if (keyCode === KEYCODE_UP) {
            helper.moveRecordFocusUp(component, event, helper);
        } else if (keyCode === KEYCODE_DOWN) {
            helper.moveRecordFocusDown(component, event, helper);
        } else {
            helper.getRecordsBySearchTerm(component, event, helper);
        }
    },

    handleRecordClick: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleRecordClick ---------------');
        event.preventDefault();
        event.stopPropagation();

        var focusIndex = event.currentTarget.dataset.index;
        component.set('v.focusIndex', focusIndex);
        helper.updateValueByFocusIndex(component, event, helper);

        // Huy add custom logic 19-Nov-2018
        var recordIndex = event.currentTarget.getAttribute("data-index");
        var records = component.get('v.records');
        var record = records[recordIndex];
        //var addressObject = JSON.parse(record.resultString);
        var addressObject = new Object();
        addressObject.placeId = record.resultString;
        
        var chooseAddressEvent = component.getEvent("chooseAnAddressEvent");
        chooseAddressEvent.setParams({
            "data": addressObject
        }).fire();
        // End Huy add custom logic 19-Nov-2018
    },

    handleNewRecordClick: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleNewRecordClick ---------------');
        event.preventDefault();
        event.stopPropagation();

        helper.addNewRecord(component, event, helper);
    },

    handlePillClick: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handlePillClick ---------------');
        event.preventDefault();
        event.stopPropagation();

        component.set('v.value', '');

        helper.getRecordsBySearchTerm(component, event, helper);

        window.setTimeout($A.getCallback(function() {
            component.find('lookupInput').getElement().focus();
        }), 1);

        // Huy add custom logic 20-Nov-2018
        var chooseAddressEvent = component.getEvent("removeAnAddressEvent");
        chooseAddressEvent.setParams({
            "data": null
        }).fire();
        // End Huy add custom logic 20-Nov-2018
    },

    handleFocusIndexChange: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleFocusIndexChange ---------------');
        var focusIndex = component.get('v.focusIndex');
        var lookupMenu = component.find('lookupMenu').getElement();

        if (!$A.util.isEmpty(lookupMenu)) {
            var options = lookupMenu.getElementsByTagName('li');
            var focusScrollTop = 0;
            var focusScrollBottom = 0;

            for (var i = 0; i < options.length; i++) {
                var optionSpan = options[i].getElementsByTagName('span')[0];

                if (i === focusIndex) {
                    $A.util.addClass(optionSpan, 'slds-has-focus');
                } else {
                    if (i < focusIndex) {
                        focusScrollTop += options[i].scrollHeight;
                    }

                    $A.util.removeClass(optionSpan, 'slds-has-focus');
                }
            }

            if (focusIndex !== null) {
                focusScrollBottom = focusScrollTop + options[focusIndex].scrollHeight;
            }

            if (focusScrollTop < lookupMenu.scrollTop) {
                lookupMenu.scrollTop = focusScrollTop;
            } else if (focusScrollBottom > lookupMenu.scrollTop + lookupMenu.clientHeight) {
                lookupMenu.scrollTop = focusScrollBottom - lookupMenu.clientHeight;
            }
        }
    },

    handleValueChange: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleValueChange ---------------');
        var value = component.get('v.value');

        if ($A.util.isEmpty(value)) {
            component.set('v.valueLabel', '');
        } else if ($A.util.isEmpty(component.get('v.valueLabel'))) {
            var countrySearch = component.get("v.countrySearch");
            console.log('@@@ countrySearch : ' + countrySearch);
            /*if(!countrySearch){
                return;
            }*/
            helper.getRecordByValue(component, event, helper);
        }
    },

    handleFilterChange: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleFilterChange ---------------');
        component.set('v.initCallsRunning', 2);
        var countrySearch = component.get("v.countrySearch");
        console.log('@@@ countrySearch : ' + countrySearch);
        /*if(!countrySearch){
            return;
        }*/
        helper.getRecordByValue(component, event, helper);
        helper.getRecentRecords(component, event, helper);

        component.find('lookupInput').getElement().value = '';
        helper.getRecordsBySearchTerm(component, event, helper);
    },

    handleLimitChange: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleLimitChange ---------------');
        component.find('lookupInput').getElement().value = '';
        var countrySearch = component.get("v.countrySearch");
        console.log('@@@ countrySearch : ' + countrySearch);
        /*if(!countrySearch){
            return;
        }*/
        helper.getRecordsBySearchTerm(component, event, helper);
    },

    handleObjectChange: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleObjectChange ---------------');
        component.set('v.initCallsRunning', 3);
        var countrySearch = component.get("v.countrySearch");
        console.log('@@@ countrySearch : ' + countrySearch);
        /*if(!countrySearch){
            return;
        }*/
        helper.getRecentRecords(component, event, helper);
        helper.getRecordByValue(component, event, helper);
        helper.getRecordLabel(component, event, helper);

        component.find('lookupInput').getElement().value = '';
        helper.getRecordsBySearchTerm(component, event, helper);
    },

    handleOrderChange: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleOrderChange ---------------');
        component.set('v.initCallsRunning', 1);
        var countrySearch = component.get("v.countrySearch");
        console.log('@@@ countrySearch : ' + countrySearch);
        /*if(!countrySearch){
            return;
        }*/
        helper.getRecentRecords(component, event, helper);

        component.find('lookupInput').getElement().value = '';
        helper.getRecordsBySearchTerm(component, event, helper);
    },

    handleSearchfieldChange: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleSearchfieldChange ---------------');
        component.set('v.initCallsRunning', 2);
        var countrySearch = component.get("v.countrySearch");
        console.log('@@@ countrySearch : ' + countrySearch);
        /*if(!countrySearch){
            return;
        }*/
        helper.getRecentRecords(component, event, helper);
        helper.getRecordByValue(component, event, helper);

        component.find('lookupInput').getElement().value = '';
        helper.getRecordsBySearchTerm(component, event, helper);
    },

    handleSubtitlefieldChange: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.handleSubtitlefieldChange ---------------');
        component.set('v.initCallsRunning', 1);
        var countrySearch = component.get("v.countrySearch");
        console.log('@@@ countrySearch : ' + countrySearch);
        /*if(!countrySearch){
            return;
        }*/
        helper.getRecentRecords(component, event, helper);

        component.find('lookupInput').getElement().value = '';
        helper.getRecordsBySearchTerm(component, event, helper);
    },

    showError: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.showError ---------------');
        var errorMessage = event.getParam('arguments').errorMessage;

        component.set('v.errorMessage', errorMessage);
        component.set('v.error', true);
    },

    hideError: function(component, event, helper) {
        console.log('@@@ --------------- strike_lookupController.hideError ---------------');
        component.set('v.errorMessage', null);
        component.set('v.error', false);
    }
})
/*Copyright 2017 Appiphony, LLC

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the 
following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following 
disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following 
disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote 
products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*/