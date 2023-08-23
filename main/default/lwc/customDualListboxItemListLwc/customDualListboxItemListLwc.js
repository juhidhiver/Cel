import { LightningElement,wire, api, track } from 'lwc';

export default class CustomDualListboxItemListLwc extends LightningElement {
    @api columnName;
    _items;
    
    @track onClickItems=[];
    @track selectedListName = [];
    @track selectedItemName;
    @track currentAllItems = [];

    @api get items(){
        return this._items;
    }
    set items(value){
        this._items = value;
        this.currentAllItems = value;
        console.log('@@@currentAllItems: ' + JSON.stringify(this.currentAllItems));
    }

    handleListClick(event){
        var itemId = event.currentTarget.id.split('-')[0];
        var items1 = JSON.parse(JSON.stringify(this._items));
        var onClickItem = this.getItem(itemId, items1);

        var itemOriginal = this.selectedItemName;

        // remove selection
        this.currentAllItems = JSON.parse(JSON.stringify(this.currentAllItems));

        if (event.shiftKey && itemOriginal) {
            var start = onClickItem.order < itemOriginal.order ? onClickItem.order : itemOriginal.order;
            var end = onClickItem.order > itemOriginal.order ? onClickItem.order : itemOriginal.order;
            var subset = this.getItems(start,end,this.currentAllItems);
            subset = this.addSelection(subset);
            this.selectedListName = subset;
            this.selectedItemName = '';
        }else if(event.ctrlKey && this.selectedListName.length > 0){
            // unselect item when click on item 2 times
            var selectedListNameToRemoveCtrl = [];
            this.selectedListName.forEach(element => {
                if(element.id === onClickItem.id){
                    selectedListNameToRemoveCtrl.push(element);
                }
            });
            
            this.selectedListName = this.selectedListName.filter(item => !selectedListNameToRemoveCtrl.includes(item));
            if(selectedListNameToRemoveCtrl.length > 0){
                this.removeSelection(selectedListNameToRemoveCtrl);
            }else { // add onCLick Item for first click 
                this.selectedListName.push(onClickItem);
                this.selectedListName = this.addSelection(this.selectedListName);
            }
            this.selectedItemName = '';
        }
        else{
            // unselect item when click on item 2 times
            var selectedListNameToRemove = [];
            this.selectedListName.forEach(element => {
                if(element.id === onClickItem.id){
                    selectedListNameToRemove.push(element);
                }
            });
            this.selectedListName = this.selectedListName.filter(item => !selectedListNameToRemove.includes(item));
            this.removeSelection(selectedListNameToRemove);

            if(this.selectedItemName && onClickItem.id === this.selectedItemName.id){
                this.selectedItemName = '';
            }
            // add onCLick Item for first click 
            if(selectedListNameToRemove.length < 1){
                onClickItem = this.addSelection([onClickItem])[0];
                this.selectedItemName = onClickItem;
                this.selectedListName.push(onClickItem);
            }  
        }

        this.dispatchEvent(new CustomEvent('handleevent', {detail: {eventName : 'onClickItem', columnName: this.columnName, selectedItemName : this.selectedItemName, selectedListName : this.selectedListName}}))
    }

    getItem(id, items) {
        var itemToReturn;
        items.forEach(item => {
            if (item.id === id){
                itemToReturn = item;
            }
        });
        return itemToReturn;
    }

    getItems( start, end, items) {
        var itemsToReturn = [];
        items.forEach(item => {
            if (item.order >= start && item.order <= end){
                itemsToReturn.push(item);
            }
        });
        return itemsToReturn;
    }

    // removeAllSelection(items) {
    //     var itemsTemp= [];
    //     items.forEach(element => {
    //         var item = element;
    //         item.selected = false;
    //         itemsTemp.push(item);
    //     });
    //     return itemsTemp;
    // }

    removeSelection( items) {
        this.currentAllItems.forEach(element => {
            items.forEach(item => {
                if(element.id === item.id){
                    element.selected = false;
                }
            });
        });
    }

    addSelection( items) {
        this.currentAllItems.forEach(item => {
            items.forEach(element => {
                if(item.id === element.id){
                    item.selected = true;
                    element.selected = true;
                }
            });
        });
        return items;
    }

    handleOnDropParent(event){
        event.preventDefault();
        event.stopPropagation();
        var targetOption = event.target;
    }

    @api removeAllSelection() {
        var currentAllItemsTmp = JSON.parse(JSON.stringify(this.currentAllItems));
        if(this.currentAllItems.length > 0){
            currentAllItemsTmp.forEach(element => {
                element.selected = false;
            });
            this.currentAllItems = currentAllItemsTmp;
        }
        this.selectedItemName = '';
        this.selectedListName = [];
    }

    handleOnDragEnterDummy(event){
        
    }

    handleOnDragLeaveDummy(event){
        
    }

    handleOnDragOverDummy(event){
        
    }

    handleReorderItemUp(event){

    }
}