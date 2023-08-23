@isTest global class MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    public String body          {get; set;}
    public Integer statusCode   {get; set;}
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        // Create a fake response
        HttpResponse res = new HttpResponse();
        String endpoint = req.getEndPoint();
        String body = '';
        System.debug('#### req: ' + endPoint + ' - ' + req.getBody());

            // rating request
        if (endpoint.endsWith('/sfdc/v1/prices')) {
            res = generateRatingResponse(req.getBody());
        
        }   // lookup NIPR request
        else if(endpoint.endsWith('/sfdc/v1/nipr')) {
            res = generateNIPRResponse(req.getBody());
        }
        else { // Invalid endpoint
            body = '{"message":"Unexpected Endpoint"}';
            res = createResponse(400, body);
        }

        return res;
    }

    public static HttpResponse createResponse(Integer statusCode, String body) {
        HttpResponse result = new HttpResponse();

        result.setHeader('Content-Type', 'application/json');
        result.setStatusCode(statusCode);
        result.setBody(body);

        return result;
    }

    public static HTTPResponse generateRatingResponse(String body) {
        HTTPResponse res = new HttpResponse();

        try {
            RatingRequest obj = (RatingRequest)JSON.deserialize(body, RatingRequest.class);
            
            Date today = System.today();
            RatingResponse.QuoteWrapper quote = new RatingResponse.QuoteWrapper();
            quote.azure_Id = obj.quote.quoteAzureId;
            quote.caT_Premium = '123';
            quote.commissionAmount = '1234';
            quote.effective_Date = today.format();
            quote.expirationDate = today.addDays(7).format();
            quote.fees = '1234';
            quote.master_Set_Id = 'abc';
            quote.nonProratedQuotePremium = '123';
            quote.nonCAT_Premium = '4321';
            quote.quotePremium = '2000';
            quote.surcharge = '1000';
            quote.status = 'Rated';
            quote.taxes = '246';
            quote.technicalPremium = '369';

            RatingResponse.OpportunityWrapper opp = new RatingResponse.OpportunityWrapper();
            opp.opportunityAzureId = obj.opportunity.opportunityAzureId;
            opp.opportunityName    = obj.opportunity.opportunityName;
            opp.netIncome          = '123';
            opp.shareHoldersEquity = '1234';
            opp.cashFlow           = '12345';
            opp.retainedErning     = '123456';
            opp.annualRevenue      = '1235';
            opp.totalRevenues      = '1236';
            opp.currentAssets      = '1237';
            opp.totalAssets        = '1238';
            opp.longTermDebt       = '1239';
            opp.currentLiabilities = '1230';
            opp.totalLiabilities   = '124';
            opp.attachmentPoint = 'Primary';

            Map<String, RatingResponse.CoverageLineItemWrapper> products =
                                         new  Map<String, RatingResponse.CoverageLineItemWrapper>();
            for (String key : obj.quote.products.keySet()) {
                RatingRequest.CoverageProductWrapper item = obj.quote.products.get(key);
                RatingResponse.CoverageLineItemWrapper newItem = new RatingResponse.CoverageLineItemWrapper();
                Integer i = 0;
                // generate main coverage
                for(RatingRequest.CoverageItem cov : item.CoverageLineItems) {
                    RatingResponse.CoverageItem newCov = new RatingResponse.CoverageItem();
                    newCov.coverageCode = cov.coverageCode;
                    newCov.azureId = cov.azureId;
                    newCov.coveragePremium = cov.coveragePremium;
                    newCov.factorDefaultValue = cov.factorDefaultValue;
                    newCov.factorMax = cov.factorMax;
                    newCov.factorMin = cov.factorMin;
                    newCov.factorValue = cov.factorValue;
                    newCov.overridePremium = cov.overridePremium;
                    newCov.included = 'true';

                    // generate sub Coverage
                    for (RatingRequest.SubCoverageItem subCov : cov.subCoverages) {
                        RatingResponse.SubCoverageItem newSubCov = new RatingResponse.SubCoverageItem();
                        newSubCov.subCoverageCode = subCov.subCoverageCode;
                        newSubCov.azureId = subCov.azureId;
                        newSubCov.coveragePremium = subCov.coveragePremium;
                        newSubCov.factorDefaultValue = subCov.factorDefaultValue;
                        newSubCov.factorMax = subCov.factorMax;
                        newSubCov.factorMin = subCov.factorMin;
                        newSubCov.factorValue = subCov.factorValue;
                        newSubCov.overridePremium = subCov.overridePremium;
                        newSubCov.included = 'true';

                        i = 0;
                        // generate limit
                        for (RatingRequest.LimitDeductible lim : subCov.limits) {
                            
                            RatingResponse.LimitItem newLim = new RatingResponse.LimitItem();
                            newLim.limitName = 'limit' + String.valueOf(i++);
                            newLim.azureId = lim.azureId;
                            newLim.coveragePremium = lim.coveragePremium;
                            newLim.factorDefaultValue = lim.factorDefaultValue;
                            newLim.factorMax = lim.factorMax;
                            newLim.factorMin = lim.factorMin;
                            newLim.factorValue = lim.factorValue;
                            newLim.increment = '1';
                            newLim.minAmt = '2';
                            newLim.maxAmt = '3';
                            newLim.optionType = 'Range';
                            newLim.optionValueDefault = '1';
                            newLim.overridePremium = lim.overridePremium;
                            newLim.optionList = new List<String>{'1','2'};
                            newSubCov.limits.add(newLim);
                        }

                        i = 0;
                        // generate limit
                        for (RatingRequest.LimitDeductible ded : subCov.deductibles) {

                            RatingResponse.DeductibleItem newDed = new RatingResponse.DeductibleItem();
                            newDed.deductibleName = 'deductible' + String.valueOf(i++);
                            newDed.azureId = ded.azureId;
                            newDed.coveragePremium = ded.coveragePremium;
                            newDed.factorDefaultValue = ded.factorDefaultValue;
                            newDed.factorMax = ded.factorMax;
                            newDed.factorMin = ded.factorMin;
                            newDed.factorValue = ded.factorValue;
                            newDed.increment = '1';
                            newDed.minAmt = '2';
                            newDed.maxAmt = '3';
                            newDed.optionType = 'Range';
                            newDed.optionValueDefault = '1';
                            newDed.overridePremium = ded.overridePremium;
                            newDed.optionList = new List<String>{'1','2'};
                            newSubCov.deductibles.add(newDed);
                        }
                        newCov.subCoverages.add(newSubCov);
                    }

                    i = 0;
                    // generate limit
                    for (RatingRequest.LimitDeductible lim : cov.limits) {
             
                        RatingResponse.LimitItem newLim = new RatingResponse.LimitItem();
                        newLim.limitName = 'limit' + String.valueOf(i++);
                        newLim.azureId = lim.azureId;
                        newLim.coveragePremium = lim.coveragePremium;
                        newLim.factorDefaultValue = lim.factorDefaultValue;
                        newLim.factorMax = lim.factorMax;
                        newLim.factorMin = lim.factorMin;
                        newLim.factorValue = lim.factorValue;
                        newLim.increment = '1';
                        newLim.minAmt = '2';
                        newLim.maxAmt = '3';
                        newLim.optionType = 'Range';
                        newLim.optionValueDefault = '1';
                        newLim.overridePremium = lim.overridePremium;
                        newLim.optionList = new List<String>{'1','2'};
                        newCov.limits.add(newLim);
                    }

                    i = 0;
                    // generate limit
                    for (RatingRequest.LimitDeductible ded : cov.deductibles) {
                        
                        RatingResponse.DeductibleItem newDed = new RatingResponse.DeductibleItem();
                        newDed.deductibleName = 'deductible' + String.valueOf(i++);
                        newDed.azureId = ded.azureId;
                        newDed.coveragePremium = ded.coveragePremium;
                        newDed.factorDefaultValue = ded.factorDefaultValue;
                        newDed.factorMax = ded.factorMax;
                        newDed.factorMin = ded.factorMin;
                        newDed.factorValue = ded.factorValue;
                        newDed.increment = '1';
                        newDed.minAmt = '2';
                        newDed.maxAmt = '3';
                        newDed.optionType = 'Range';
                        newDed.optionValueDefault = '1';
                        newDed.overridePremium = ded.overridePremium;
                        newDed.optionList = new List<String>{'1','2'};
                        newCov.deductibles.add(newDed);
                    }

                    newItem.CoverageLineItems.add(newCov);
                }

                products.put(key, newItem);
            }

            Map<String, List<RatingResponse.RatingModifier>> modifierMap =
                                         new  Map<String, List<RatingResponse.RatingModifier>>();
            for (String key : obj.opportunity.products.keySet()) {
                List<RatingRequest.RatingModifier> items = obj.opportunity.products.get(key);
                List<RatingResponse.RatingModifier> modifiers = new List<RatingResponse.RatingModifier>();
                for(RatingRequest.RatingModifier item : items) {
                    RatingResponse.RatingModifier newItem = new RatingResponse.RatingModifier();
                    newItem.azureID = item.azureID;
                    newItem.ratingModifierName = item.ratingModifierName;
                    newItem.ratingModifierValue = item.ratingModifierValue;
                    //newItem.factorMin = item.factorMin;
                    //newItem.factorMax = item.factorMax;
                    //newItem.factorValue = item.factorValue;
                    newItem.format = item.format;
                    //newItem.defaultValue = item.defaultValue;

                    modifiers.add(newItem);
                }
                modifierMap.put(key, modifiers);
            }

            RatingResponse resObj = new RatingResponse();
            resObj.quote = quote;
            resObj.opportunity = opp;
            resObj.products = products;
            resObj.ratingModifiers = modifierMap;

            String jsonObj = JSON.serialize(resObj);
            res = createResponse(200, jsonObj);

        } catch (Exception ex) {
            res = createResponse(400, 'Failed to create response');
        }
        return res;
    }

    public HttpResponse generateNIPRResponse(String body) {
        System.debug('request body: ' + body);
        HttpResponse res = new HttpResponse();
        Map<String, Object> reqMap = (Map<String, Object>) JSON.deserializeUntyped(body);
        if(reqMap.containsKey('agencyLookup')) { 
            Map<String, Object>  feinMap = (Map<String, Object>) reqMap.get('agencyLookup');
            if(feinMap.containsKey('fein')) {
                String fein = String.valueOf(feinMap.get('fein'));
                System.debug('BBBBBBBBBBB ' + fein);
                switch on fein {
                    when '651106324' {
                        String resBody = '{"isValidAgencyFEIN": true,"npn": "8904483"}';
                        res = createResponse(200, resBody);
                    }
                    when '' {
                        String resBody = '{"Message": "400 - there is no input data for NIPR to call "}';
                        res = createResponse(400, resBody);
                    }
                    when else {
                        String resBody = '{"error": {"code": "NoResponse","message": "Server is unavailable" }}';
                        res = createResponse(415, resBody);
                    }
                }
            }

        }
        System.debug('Mock response NIPR: ' + res + ': ' + res.getBody());
        
        return res;
    }

}