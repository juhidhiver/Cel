({
    init: function (component) {
        var allData = component.get("v.allData");
        var pageSize = component.get("v.itemsPerPage");
        var pages = Math.ceil(allData.length / pageSize);
        
        component.set("v.currentPage", 1);
        component.set("v.totalPages", pages);
    },
    
    // create pagination buttons list
	getPages: function(component, currentPage) {
        var pages = [];
        var maxSize = component.get("v.maxSize");
        var rotate = component.get("v.rotate");
        var totalPages = component.get("v.totalPages");
        
        var forceEllipses = component.get("v.forceEllipses");
        var boundaryLinkNumbers = component.get("v.boundaryLinkNumbers");

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
    },
    
    // get data for datatable and pagination buttons
    buildData: function(component, helper) {
        var data = [];
        var pageNumber = component.get("v.currentPage");
        var pageSize = component.get("v.itemsPerPage");
		var totalPages = component.get("v.totalPages");
        var allData = component.get("v.allData");
        
		var startNum = (pageNumber - 1) * pageSize;
        var endNum = (pageNumber * pageSize) - 1;

        var pages = helper.getPages(component, pageNumber);

        component.set("v.pageList", pages);
        for (var i = startNum;i <= endNum; i++){
            if (allData[i]) {
                data.push(allData[i]);
            }
        }

        component.set("v.data", data);
    },
    
    navigateTo: function(component, helper, pageNumber) {
        component.set("v.currentPage", pageNumber);
        component.set("v.currentPageStr", pageNumber.toString());
        // get data table and page buttons list
        helper.buildData(component, helper);
        // Notify parent component to update datatable
        helper.notifyPageChanged(component);
        // change navigation buttons state
        helper.changeButtonState(component);
    },
    
    // fire event to notify page is changed
    notifyPageChanged: function(component) {
        var data = component.get("v.data");

        var cmpEvent = component.getEvent("pageChangedEvt");
        //var cmpEvent = $A.get("e.c:PageChangedEvent");
        cmpEvent.setParams({
            "message" : "Page Changed",
            "data" : data
        });
        cmpEvent.fire();
    },
    
    // change navigation buttons state
    changeButtonState: function(component) {
        var totalPages = component.get("v.totalPages");
        var currentPage = component.get("v.currentPage");
        var disableFirst = false;
        var disableLast = false;
        
        if (currentPage == 1) {
            disableFirst = true;
        }
        
        if (currentPage == totalPages) {
            disableLast = true;
        }
        
        component.set("v.disablePrev", disableFirst);
        component.set("v.disableNext", disableLast);
    }
})