import { LightningElement,wire,api,track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getDataTable from '@salesforce/apex/RelatedListController.getDataTable';

export default class PaginationLwc extends LightningElement {
    @api currenrecordid;
    @track data = [];//sObject[]
    @track allData = [];//sObject[]
    @api columns = [];//List
    @api columnsToDisplay;//List
    @track disablePrev = true;
    @track disableNext = true;
    @api currpage;
    @track currentPage = 1;
    @track currentPageStr = '1';
    @track itemsPerPage = 5;
    @track totalPages = 5;

    @api objectApiName;

    @api childRecordTypeId;

    
    _pageList = undefined;//List

    set pageList(value) {
        var temp = JSON.parse(JSON.stringify(value));
        var newList = [];
        var currentPageStr = this.currentPageStr;
        temp.forEach(function(record) { 
            //console.log('record:' + record + ' this.currentPageStr:' + currentPageStr);
            var newRecord = {};
            if(record == '...') {
                newRecord.isMatched = true;
                newRecord.name = record;
     
            } else {
                newRecord.isMatched = false;
                newRecord.name = record;
            }
            
            if(currentPageStr == record) {
                newRecord.isSelected = true;
            } else {
                newRecord.isSelected = false;
            }
            newList.push(newRecord);
        });
        console.log('this.currpage:' + this.currpage);
        //this.currentPage = this.currpage;
        if(newList) {
            this._pageList = newList;
        } else {
            this.currentPage = 0;
        }
        
    }

    @api get pageList() {
        return this._pageList;
    }
    @track maxSize = 8;//List
    @track rotate = true;//List
    @track forceEllipses = true;//List
    @track boundaryLinkNumbers = true;//List

    refreshTable;


    @api refreshDataTable() {
        refreshApex(this.refreshTable);
    }

    //Controler
    doInit() {
        this.init();
		this.navigateTo(1);
	}
    
    handlePrev() {        
        var pageNumber = this.currentPage - 1;
        this.navigateTo(pageNumber);
    }
    
    handleNext() {        
        var pageNumber = parseInt(this.currentPage) + 1;
        this.navigateTo(pageNumber);
    }
    
    handleFirst() {        
        this.navigateTo(1);
    }
    
    handleLast() {    
        var pageNumber = this.totalPages;
        this.navigateTo(pageNumber);
    }
    
    handlePage(event) {  
        console.log('handlePage:' + event.target.name) 
        var pageNumber = event.target.name;
        this.navigateTo(pageNumber);
    }
    
    pageChanged() {
        this.notifyPageChanged();
    }
    //End

    init() {
        var allData = this.allData;
        var pageSize = this.itemsPerPage;
        var pages = Math.ceil(allData.length / pageSize);
        this.currentPage = 1;
        this.totalPages = pages;
    }
    
    // create pagination buttons list
	getPages(currentPage) {
        var pages = [];
        var maxSize = this.maxSize;
        var rotate = this.rotate;
        var totalPages = this.totalPages;
        
        var forceEllipses = this.forceEllipses;
        var boundaryLinkNumbers = this.boundaryLinkNumbers;

        // Default page limits
    	var startPage = 1;
        var endPage = totalPages;
        var isMaxSized = maxSize < totalPages;
        
        // recompute if maxSize
        if (isMaxSized) {
            if (rotate) {
            	// Current page is displayed in the middle of the visible ones
        		startPage = Math.max(currentPage - Math.floor(maxSize / 2), 1);
                endPage = startPage + maxSize - 1;
                
                // Adjust if limit is exceeded
                if (endPage > totalPages) {
                  endPage = totalPages;
                  startPage = endPage - maxSize + 1;
                }
            }
        } else {
            // Visible pages are paginated with maxSize
        	startPage = (Math.ceil(currentPage / maxSize) - 1) * maxSize + 1;
        
            // Adjust last page if limit is exceeded
        	endPage = Math.min(startPage + maxSize - 1, totalPages);
        }
        
        // Add page number links
        for (var number = startPage; number <= endPage; number++) {
          var page = number.toString();
          pages.push(page);
        }
        
        // Add links to move between page sets
        if (isMaxSized && maxSize > 0 && 
            (!rotate || forceEllipses || boundaryLinkNumbers)) {
            if (startPage > 1) {
                // need ellipsis for all options unless range 
                // is too close to beginning
                if (!boundaryLinkNumbers || startPage > 3) { 
                	var previousPageSet = '...';
                	pages.unshift(previousPageSet);
                }
                
                if (boundaryLinkNumbers) {
                    // need to replace ellipsis when the buttons 
                    // would be sequential
                	if (startPage === 3) { 
                        var secondPageLink = '2';
            			pages.unshift(secondPageLink);
                    }
                    
                    //add the first page
                	var firstPageLink = '1';
                  	pages.unshift(firstPageLink);  
                }
            }
            
            if (endPage < totalPages) {
                // need ellipsis for all options unless range 
                // is too close to end
            	if (!boundaryLinkNumbers || endPage < totalPages - 2) {
                	var nextPageSet = '...';
        			pages.push(nextPageSet);
                }
                
                if (boundaryLinkNumbers) {
                    // need to replace ellipsis when the buttons 
                    // would be sequential
                	if (endPage === totalPages - 2) { 
                        var secondToLast = (totalPages - 1);
                        var secondToLastPageLink = secondToLast.toString();
                        pages.push(secondToLastPageLink);
                    }
                    
                    //add the last page
                	var lastPageLink = totalPages.toString();
                  	pages.push(lastPageLink);  
                }
            }
        }
        return pages;
    }
    
    // get data for datatable and pagination buttons
    buildData() {
        var data = [];
        var pageNumber = this.currentPage;
        var pageSize = this.itemsPerPage;
        var allData = this.allData;
        
        var startNum = (pageNumber - 1) * pageSize;
        var endNum = (pageNumber * pageSize) - 1;
        var pages = this.getPages(pageNumber);

        this.pageList = pages;
        for (var i = startNum;i <= endNum; i++){
            if (allData[i]) {
                data.push(allData[i]);
            }
        }
        this.data = data; //console.log('buildData 77777777777777');

    }
    
    navigateTo(pageNumber) {
        this.currentPage = pageNumber;
        this.currentPageStr = pageNumber.toString();
        // get data table and page buttons list
        this.buildData();
        // Notify parent component to update datatable
        this.notifyPageChanged();
        // change navigation buttons state
        this.changeButtonState();
        console.log('navigachangeButtonStateteTo 234:' + pageNumber);
    }
    
    // fire event to notify page is changed
    notifyPageChanged() {
        var data = this.data;
        var params = {"data" : data,"columns" : this.columns, "currentpage" : this.currentPage};
        //console.log('notifyPageChanged 222222222222222:' + JSON.stringify(data));
        const event = new CustomEvent('pagechanged', {
            detail: params
        });
        // Fire the event from c-tile
        this.dispatchEvent(event);
        /*
        var cmpEvent = component.getEvent("pageChangedEvt");
        cmpEvent.setParams({
            "message" : "Page Changed",
            "data" : data
        });
        cmpEvent.fire();*/
    }
    
    // change navigation buttons state
    changeButtonState() {
        console.log('currentPage:' + ' totalPages: 258');
        var totalPages = this.totalPages;
        var currentPage = this.currentPage;
        var disableFirst = false;
        var disableLast = false;
        console.log('currentPage:' + currentPage + ' totalPages:' + totalPages);
        
        if (currentPage == 1) {
            disableFirst = true;
        }
        
        if (currentPage == totalPages || totalPages == 0) {
            disableLast = true;
        }
        this.disablePrev = disableFirst;
        this.disableNext = disableLast;
    }
    //End


    @wire(getDataTable,{objectType:'$objectApiName',parentRecordId:'$currenrecordid',fields:'$columnsToDisplay',orderBy:'ASC',recordId:'$childRecordTypeId'})
    imperativeWiring(data1) {
        
        console.log('childRecordTypeId:' + this.childRecordTypeId + ';;currenrecordid:' + this.currenrecordid);
        console.log('444  22222222 5555:' + JSON.stringify(data1));
        this.refreshTable = data1;
        const { data, error } = data1;
        if(data && data.isSuccess) {
            
            var table = data.data;
            var allData = table.data;
           
            this.columns = table.columns;
            this.allData = allData;
            //this.doInit();
            var curr1 = this.currentPage;
            console.log('Current page 290:' + curr1);
            this.init();
            this.navigateTo(curr1);
        } else if(error) {
            console.log(error);
        }
    }
}