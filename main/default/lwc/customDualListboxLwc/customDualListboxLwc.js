import { LightningElement, track , api} from 'lwc';

export default class CustomDualListboxLwc extends LightningElement {

    @api leftValues;
    @api rightValues;
    @api disableProsAndCons;

    @api sourceLabel="Options";
    @api selectedLabel="Values";

    @track onClickItemLeft;
    @track onClickItemListLeft = [];
    @track onClickItemRight;
    @track onClickItemListRight = [];

    @track currentLeftValues;
    @track currentRightValues;

    moveLeftToRight(event){
        var leftValuesTmp = JSON.parse(JSON.stringify(this.leftValues));
        var rightValuesTmp = JSON.parse(JSON.stringify(this.rightValues));
        if(this.onClickItemListLeft.length > 1){ // click list items
            this.onClickItemListLeft.forEach(element => {
                element.order = rightValuesTmp.length + 1;
                rightValuesTmp.push(element);
            });
            leftValuesTmp.forEach(leftValue => {
                this.onClickItemListLeft.forEach(element => {
                    if(leftValue.id === element.id){
                        leftValuesTmp = leftValuesTmp.filter(value => value != leftValue);
                    }
                });
            });
            
        }else{  // click one item
            this.onClickItemLeft.order = rightValuesTmp.length + 1;
            rightValuesTmp.push(this.onClickItemLeft);
            leftValuesTmp.forEach(leftValue => {
                if(leftValue.id === this.onClickItemLeft.id){
                    leftValuesTmp = leftValuesTmp.filter(value => value != leftValue);
                }
            });
        }
        // reorder
        this.renumberItems(leftValuesTmp);
        this.sortItems(leftValuesTmp);
        this.renumberItems(rightValuesTmp);
        this.sortItems(rightValuesTmp);
        // unselect
        this.unSelectItem(rightValuesTmp);
        this.unSelectItem(leftValuesTmp);

        this.onClickItemListLeft = [];
        this.onClickItemListRight = [];

        this.onClickItemRight = '';
        this.onClickItemLeft = '';

        this.template.querySelectorAll("c-custom-dual-listbox-item-list-lwc").forEach(element => {
            element.removeAllSelection();
        });

        this.dispatchEvent(new CustomEvent('changevalue', {detail: {leftValues : leftValuesTmp , rightValues : rightValuesTmp}}));
    }

    moveRightToLeft(event){
        var leftValuesTmp = JSON.parse(JSON.stringify(this.leftValues));
        var rightValuesTmp = JSON.parse(JSON.stringify(this.rightValues));
        if(this.onClickItemListRight.length > 1){ // click list items
            this.onClickItemListRight.forEach(element => {
                element.order = leftValuesTmp.length + 1;
                leftValuesTmp.push(element);
            });
            rightValuesTmp.forEach(rightValue => {
                this.onClickItemListRight.forEach(element => {
                    if(rightValue.id === element.id){
                        rightValuesTmp = rightValuesTmp.filter(value => value != rightValue);
                    }
                });
            });
        }else{  // click one item
            this.onClickItemRight.order = leftValuesTmp.length + 1;
            leftValuesTmp.push(this.onClickItemRight);
            rightValuesTmp.forEach(rightValue => {
                if(rightValue.id === this.onClickItemRight.id){
                    rightValuesTmp = rightValuesTmp.filter(value => value != rightValue);
                }
            });
        }
        // reorder
        this.renumberItems(rightValuesTmp);
        this.sortItems(rightValuesTmp);
        this.renumberItems(leftValuesTmp);
        this.sortItems(leftValuesTmp);
        // unselect
        this.unSelectItem(rightValuesTmp);
        this.unSelectItem(leftValuesTmp);

        // this.currentLeftValues = leftValuesTmp;
        // this.currentRightValues = rightValuesTmp;

        this.onClickItemListLeft = [];
        this.onClickItemListRight = [];
        this.onClickItemRight = '';
        this.onClickItemLeft = '';

        this.template.querySelectorAll("c-custom-dual-listbox-item-list-lwc").forEach(element => {
            element.removeAllSelection();
        });

        this.dispatchEvent(new CustomEvent('changevalue', {detail: {leftValues : leftValuesTmp , rightValues : rightValuesTmp}}));
    }

    handleEvent(event){
        if(event.detail.eventName === 'onClickItem'){
            if(event.detail.columnName === this.sourceLabel){
                this.onClickItemLeft = event.detail.selectedItemName;
                this.onClickItemListLeft = event.detail.selectedListName;
            }else if(event.detail.columnName === this.selectedLabel){
                this.onClickItemRight = event.detail.selectedItemName;
                this.onClickItemListRight = event.detail.selectedListName;
            }
            this.dispatchEvent(new CustomEvent(
                'clickitems', {detail: {
                    onClickItemLeft : this.onClickItemLeft , 
                    onClickItemListLeft : this.onClickItemListLeft,
                    onClickItemRight : this.onClickItemRight,
                    onClickItemListRight : this.onClickItemListRight
                }}
            ));
        }
    }

    unSelectItem(items){
        if(items && items.length > 0){
            items.forEach(element => {
                element.selected = false;
            });
        }
    }

    sortItems( items) {
        if(items && items.length > 0){
            items.sort(function(a, b) {
                return a.order > b.order ? 1 : -1;
            });
        }
        return items;
    }
    
    renumberItems( items) {
        if(items && items.length > 0){
            items = this.sortItems(items);
            items.forEach(function(item, index) {
                item.order = index;
            });
        }
        return items;
    }
}