/**
 * @description       : 
 * @author            : Vinayesh
 * @group             : 
 * @last modified on  : 02-22-2022
 * @last modified by  : Vinayesh
**/
global with sharing class RatingFactorsHelper {
    
    /**
     * Return factors range map based on State Code of Opportunity Account Billing Address.
     */
    
    public static Map<String, Map<String, FactorRange>> getRatingRangesMap(String oppId) 
    {
        Map<String, Map<String, FactorRange>> factorRangeMap = new Map<String, Map<String, FactorRange>>();
        Opportunity opp = getOpp(oppId);
        String currState = '';
        if(opp != null){
            currState = opp.Account.BillingStateCode;
        }

        /*List<Rating_Reference_Name__c> ratingRefNames =  
                [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                   (SELECT Rating_Specific_Value_Id__c, Reference_Name_Id__r.Reference_Name__c, 
                    Specific_Value__c, Factor__c, UW_Value__c, Effective_Date__c, 
                    Expiration_Date__c, UW_Code__c, Minimum_Premium__c, Sort_Order__c, State__c 
                    FROM Rating_Specific_Values__r
                    WHERE State__c = :currState)   
                FROM Rating_Reference_Name__c];*/
        
        for(Rating_Reference_Name__c refName : [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                                            (SELECT Rating_Specific_Value_Id__c, Reference_Name_Id__r.Reference_Name__c, 
                                             Specific_Value__c, Factor__c, UW_Value__c, Effective_Date__c, 
                                             Expiration_Date__c, UW_Code__c, Minimum_Premium__c, Sort_Order__c, State__c 
                                             FROM Rating_Specific_Values__r
                                             WHERE State__c = :currState)   
                                            FROM Rating_Reference_Name__c]){
            if(refName.Rating_Specific_Values__r.size() > 0){
                Map<String, FactorRange> optionsRangeMap = new Map<String, FactorRange>();
                factorRangeMap.put(refName.Reference_Name__c, optionsRangeMap);

                for(Rating_Specific_Value__c rSpecVal : refName.Rating_Specific_Values__r){
                    if(rSpecVal.Effective_Date__c != null && rSpecVal.Expiration_Date__c != null &&
                       ((Date.today() >= rSpecVal.Effective_Date__c) && (Date.today() <= rSpecVal.Expiration_Date__c))){

                        String specVal = rSpecVal.Specific_Value__c;
                        List<String> parts = specVal.split(';');
                        if(parts.size() > 0){
                            string optVal = parts[0];
                          
                            FactorRange optRange = new FactorRange();
                            optionsRangeMap.put(optVal, optRange);
                           
                            if(rSpecVal.Factor__c != null){
                                String optFactor = rSpecVal.Factor__c.trim();
                                if(optFactor.left(1) != '{') optFactor = '{' + optFactor;
                                if(!optFactor.endsWith('}')) optFactor += '}';
                                //optFactor = '{' + optFactor + '}';
                                if(optFactor.containsIgnoreCase('medium')){
                                    FactorRangeLowMidHigh optRangeMid = (FactorRangeLowMidHigh)JSON.deserialize(optFactor, FactorRangeLowMidHigh.class);
                                    optRange.Range_Lower = optRangeMid.Low;
                                    optRange.Range_Upper = optRangeMid.High;
                                    optionsRangeMap.put(optVal, optRange);
                                }
                                else if(optFactor.containsIgnoreCase('range_upper')){
                                    optRange = (FactorRange)JSON.deserialize(optFactor, FactorRange.class);
                                    optionsRangeMap.put(optVal, optRange);
                                   
                                }
                                else if(optFactor.containsIgnoreCase('factor') && optFactor.containsIgnoreCase('hazard_group') ){
                                    FactorRangeFlat optRangrFlat = (FactorRangeFlat)JSON.deserialize(optFactor, FactorRangeFlat.class);
                                    optRange.Range_Lower = optRangrFlat.factor;
                                    optRange.Range_Upper = optRangrFlat.factor;
                                    optionsRangeMap.put(optVal, optRange);
                                }
                                else{
                                    if(rSpecVal.Factor__c.remove('.').isNumeric()){
                                        optRange.Range_Lower = rSpecVal.Factor__c;
                                        optRange.Range_Upper = rSpecVal.Factor__c;
                                        optionsRangeMap.put(optVal, optRange);
                                    }
                                }                               
                            }                       
                        }
                    }
                    
                }
                System.debug(refName.Rating_Reference_Name_Id__c + ' : ' + factorRangeMap.get(refName.Rating_Reference_Name_Id__c));
            }               
        }

        return factorRangeMap;
    }

    public static Opportunity getOpp(String oppId) {
        List<Opportunity> oppRec = [SELECT Id, Account.BillingState, Account.BillingStateCode, Account.Billing_County__c, Total_Revenues__c, AnnualRevenue__c,Ratable_Employees__c,Plan_Assets__c 
                                    FROM Opportunity
                                    WHERE Id =: oppId];
        if(!oppRec.isEmpty())
            return oppRec[0];
        return null;
    }
    
    public static StateRange getRatingRangesState(String oppId) {
        
        Opportunity opp = getOpp(oppId);
        String currState = '';
        if(opp != null){
            currState = opp.Account.BillingStateCode;
        }
        
        StateRange optRange = new StateRange();
        
        List<Rating_Reference_Name__c> ratingRefNames =  
                [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                   (SELECT Rating_Specific_Value_Id__c, Reference_Name_Id__r.Reference_Name__c, 
                    Specific_Value__c, Factor__c, UW_Value__c, Effective_Date__c, 
                    Expiration_Date__c, UW_Code__c, Minimum_Premium__c, Sort_Order__c, State__c 
                    FROM Rating_Specific_Values__r
                    WHERE Specific_Value__c = :currState)   
                FROM Rating_Reference_Name__c Where Reference_Name__c = 'Common_State'];
        
        
        List<Rating_Specific_Value__c> ratingSpecificValues =  ratingRefNames[0].Rating_Specific_Values__r;
        
        if(!ratingSpecificValues.isEmpty()){
            Rating_Specific_Value__c rSpecificVal = ratingSpecificValues[0];
            if(rSpecificVal.Factor__c != null){
                String optFactor = rSpecificVal.Factor__c.trim();
                if(optFactor.left(1) != '{') optFactor = '{' + optFactor;
                if(!optFactor.endsWith('}')) optFactor += '}';
                // String optFactor = rSpecificVal.Factor__c.replace('{','').replace('}','');
                // optFactor = '{' + optFactor + '}';
                optRange = (StateRange)JSON.deserialize(optFactor, StateRange.class);
            }  
        }
        
        return optRange;
        
    }

    public static Decimal getRatingRangesBaseRate(String productName, String oppId, String refName) {
        
        Opportunity opp = getOpp(oppId);
        Decimal totalRevenue;
        if(opp != null){
            totalRevenue = productName == 'Fiduciary' ? opp.Plan_Assets__c : opp.AnnualRevenue__c;
        }

        System.debug('totalRevenue'+totalRevenue);
        
        Decimal baseRate;

        if(refName != null){

            List<Rating_Reference_Name__c> ratingRefNames =  
                    [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                    (SELECT Rating_Range_Value__c, Reference_Name_Id__r.Reference_Name__c, 
                        Factor__c, Upper_Value__c, Lower_Value__c, Effective_Date__c, 
                        Expiration_Date__c, Minimum_Premium__c FROM Rating_Range_Values__r) 
                        //Where Lower_Value__c > :totalRevenue AND Upper_Value__c < :totalRevenue) 
                    FROM Rating_Reference_Name__c Where Reference_Name__c = :refName];
            
            
            List<Rating_Range_Value__c> ratingRangeValues =  ratingRefNames[0].Rating_Range_Values__r;
            
            if(!ratingRangeValues.isEmpty()){
                for(Rating_Range_Value__c rRangeVal :ratingRangeValues){
                    System.debug('rRangeVal.Lower_Value__c'+rRangeVal.Lower_Value__c);
                    System.debug('rRangeVal.Upper_Value__c'+rRangeVal.Upper_Value__c);
                    if(rRangeVal.Factor__c != null && rRangeVal.Lower_Value__c <= totalRevenue && rRangeVal.Upper_Value__c > totalRevenue){
                        System.debug('rRangeVal.Factor__c'+rRangeVal.Factor__c);
                        baseRate = Decimal.valueOf(rRangeVal.Factor__c);
                    }  
                }
                
            }

        }
        
        return baseRate;
        
    }

    public static List<LimitILF> getLimitILF() {
        
        /*Opportunity opp = getOpp(oppId);
        Decimal totalRevenue;
        if(opp != null){
            totalRevenue = opp.AnnualRevenue__c;
        }*/
        
        List<LimitILF> listOptRange = new List<LimitILF>();

        List<Rating_Reference_Name__c> ratingRefNames =  
                [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                (SELECT Rating_Range_Value__c, Reference_Name_Id__r.Reference_Name__c, 
                    Factor__c, Upper_Value__c, Lower_Value__c, Effective_Date__c, 
                    Expiration_Date__c, Minimum_Premium__c FROM Rating_Range_Values__r ) 
                FROM Rating_Reference_Name__c Where Reference_Name__c = 'DO_LimitRetentionILF'];
        
        
        List<Rating_Range_Value__c> ratingRangeValues =  ratingRefNames[0].Rating_Range_Values__r;
        
        if(!ratingRangeValues.isEmpty()){
            for(Rating_Range_Value__c rRangeVal : ratingRangeValues){
                LimitILF optRange = new LimitILF();
                String optFactor = rRangeVal.Factor__c.trim();
                if(optFactor.left(1) != '{') optFactor = '{' + optFactor;
                if(!optFactor.endsWith('}')) optFactor += '}';
                // String optFactor = rRangeVal.Factor__c.replace('{','').replace('}','');
                // optFactor = '{' + optFactor + '}';
                optRange = (LimitILF)JSON.deserialize(optFactor, LimitILF.class);
                listOptRange.add(optRange);
            }
        }

        return listOptRange;
        
    }

    public static List<LimitILF> getLimitILF(String productName, String refName) {
        
        /*Opportunity opp = getOpp(oppId);
        Decimal totalRevenue;
        if(opp != null){
            totalRevenue = opp.AnnualRevenue__c;
        }*/
        
        List<LimitILF> listOptRange = new List<LimitILF>();

        List<Rating_Reference_Name__c> ratingRefNames =  
                [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                (SELECT Rating_Range_Value__c, Reference_Name_Id__r.Reference_Name__c, 
                    Factor__c, Upper_Value__c, Lower_Value__c, Effective_Date__c, 
                    Expiration_Date__c, Minimum_Premium__c FROM Rating_Range_Values__r ) 
                FROM Rating_Reference_Name__c Where Reference_Name__c = :refName];
        
        
        List<Rating_Range_Value__c> ratingRangeValues =  ratingRefNames[0].Rating_Range_Values__r;
        
        if(!ratingRangeValues.isEmpty()){
            for(Rating_Range_Value__c rRangeVal : ratingRangeValues){
                LimitILF optRange = new LimitILF();
                String optFactor = rRangeVal.Factor__c.trim();
                if(optFactor.left(1) != '{') optFactor = '{' + optFactor;
                if(!optFactor.endsWith('}')) optFactor += '}';
                // String optFactor = rRangeVal.Factor__c.replace('{','').replace('}','');
                // optFactor = '{' + optFactor + '}';
                optRange = (LimitILF)JSON.deserialize(optFactor, LimitILF.class);
                /*if(productName == 'EPL'){
                    LimitILFEPL optRangeEPL = new LimitILFEPL();
                    optRangeEPL = (LimitILFEPL)JSON.deserialize(optFactor, LimitILFEPL.class);
                    optRange.lowerBound = optRangeEPL.lower_limit;
                    optRange.upperBound = optRangeEPL.upper_limit;
                    optRange.lowerFactor = optRangeEPL.lower_factor != null ? optRangeEPL.lower_factor : 'N/A';
                    optRange.upperFactor = optRangeEPL.upper_factor != null ? optRangeEPL.upper_factor : 'N/A';
                    if(optRangeEPL.calculate_factor != 'interpolate'){
                        optRange.formulaExponent = '0.5';
                    }
                    else{
                        optRange.formulaExponent = 'N/A';
                    }
                }
                else{
                    optRange = (LimitILF)JSON.deserialize(optFactor, LimitILF.class);
                }*/
                listOptRange.add(optRange);
            }
        }

        return listOptRange;
        
    }


    public static List<RetentionILF> getRetentionILF(String oppId, String productName, String refName, Decimal RatableEmployee) {
        
        Opportunity opp = getOpp(oppId);
        Decimal totalRevenue;
        if(opp != null){
            if(productName == 'D&O' || productName == 'Crime'){
                totalRevenue = opp.AnnualRevenue__c;
            }
            else if(productName == 'EPL'){
                totalRevenue = RatableEmployee;
            }
            
        }
        List<RetentionILF> listOptRange = new List<RetentionILF>();
        
        if(productName != 'Fiduciary'){
            
            List<Rating_Reference_Name__c> ratingRefNames =  
                        [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                        (SELECT Name, Reference_Name_Id__r.Reference_Name__c, 
                            Factor__c, Rating_Range_Id__r.Upper_Value__c, Rating_Range_Id__r.Lower_Value__c, Rating_Range_Id2__c,
                            //Rating_Range_Id2__r.Upper_Value__c, Rating_Range_Id2__r.Lower_Value__c, 
                            Effective_Date__c, Expiration_Date__c, Minimum_Premium__c FROM Rating_Matrix_Value__r) 
                        FROM Rating_Reference_Name__c Where Reference_Name__c = :refName];
                
                
            List<Rating_Matrix_Value__c> ratingMatrixValues =  ratingRefNames[0].Rating_Matrix_Value__r;
            System.debug('ratingMatrixValues'+ratingMatrixValues);
            if(!ratingMatrixValues.isEmpty()){
                List<String> listRatingValIds = new List<String>();
                String ratingValId;
                for(Rating_Matrix_Value__c rMatrixVal : ratingMatrixValues){
                    if(rMatrixVal.Rating_Range_Id2__c != null){
                        listRatingValIds.add(rMatrixVal.Rating_Range_Id2__c);
                    }
                }
                for(Rating_Range_Value__c rRangeVal : [Select Id, Upper_Value__c, Lower_Value__c, Rating_Range_Value__c from Rating_Range_Value__c where Id in :listRatingValIds]){
                    if(rRangeVal.Upper_Value__c > totalRevenue && rRangeVal.Lower_Value__c <= totalRevenue){
                        ratingValId = rRangeVal.Id;
                    }
                }
                System.debug('ratingValId'+ratingValId);
                for(Rating_Matrix_Value__c rMatrixVal : ratingMatrixValues){
                    if(ratingValId == rMatrixVal.Rating_Range_Id2__c || productName == 'Fiduciary'){
                        RetentionILF optRange = new RetentionILF();
                        String optFactor = rMatrixVal.Factor__c.trim();
                        if(optFactor.left(1) != '{') optFactor = '{' + optFactor;
                        if(!optFactor.endsWith('}')) optFactor += '}';
                        // String optFactor = rMatrixVal.Factor__c.replace('{','').replace('}','');
                        // optFactor = '{' + optFactor + '}';
                        System.debug('optFactor'+optFactor);
                        optRange = (RetentionILF)JSON.deserialize(optFactor, RetentionILF.class);
                        /*if(productName == 'EPL'){
                            LimitILFEPL optRangeEPL = new LimitILFEPL();
                            optRangeEPL = (LimitILFEPL)JSON.deserialize(optFactor, LimitILFEPL.class);
                            optRange.LowerValue = optRangeEPL.lower_limit;
                            optRange.UpperValue = optRangeEPL.upper_limit;
                            optRange.lowerFactor = optRangeEPL.lower_factor;
                            optRange.upperFactor = optRangeEPL.upper_factor;
                        }
                        else{
                            optRange = (RetentionILF)JSON.deserialize(optFactor, RetentionILF.class);
                        }*/
                        listOptRange.add(optRange);
                    } 
                }
            }
            
        }
        else{
            List<LimitILF> listLimitILF = getLimitILF(productName,refName);
            for(LimitILF objLimitILF :listLimitILF){
                RetentionILF objRetentionILF = new RetentionILF();
                objRetentionILF.LowerValue = objLimitILF.lowerBound;
                objRetentionILF.UpperValue = objLimitILF.upperBound;
                objRetentionILF.lowerFactor = objLimitILF.lowerFactor;
                objRetentionILF.upperFactor = objLimitILF.upperFactor;
                listOptRange.add(objRetentionILF);
            }
            
        }

        


        return listOptRange;
        
    }

    public static List<RetentionILF> getRetentionILF(String oppId) {
        
        Opportunity opp = getOpp(oppId);
        Decimal totalRevenue;
        if(opp != null){
            totalRevenue = opp.AnnualRevenue__c;
        }
        List<RetentionILF> listOptRange = new List<RetentionILF>();

        List<Rating_Reference_Name__c> ratingRefNames =  
                [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                (SELECT Name, Reference_Name_Id__r.Reference_Name__c, 
                    Factor__c, Rating_Range_Id__r.Upper_Value__c, Rating_Range_Id__r.Lower_Value__c, Rating_Range_Id2__c,
                    //Rating_Range_Id2__r.Upper_Value__c, Rating_Range_Id2__r.Lower_Value__c, 
                    Effective_Date__c, Expiration_Date__c, Minimum_Premium__c FROM Rating_Matrix_Value__r) 
                FROM Rating_Reference_Name__c Where Reference_Name__c = 'DO_RetentionModifier'];
        
        
        List<Rating_Matrix_Value__c> ratingMatrixValues =  ratingRefNames[0].Rating_Matrix_Value__r;
        
        if(!ratingMatrixValues.isEmpty()){
            List<String> listRatingValIds = new List<String>();
            String ratingValId;
            for(Rating_Matrix_Value__c rMatrixVal : ratingMatrixValues){
                if(rMatrixVal.Rating_Range_Id2__c != null){
                    listRatingValIds.add(rMatrixVal.Rating_Range_Id2__c);
                }
            }
            for(Rating_Range_Value__c rRangeVal : [Select Id, Upper_Value__c, Lower_Value__c, Rating_Range_Value__c from Rating_Range_Value__c where Id in :listRatingValIds]){
                if(rRangeVal.Upper_Value__c > totalRevenue && rRangeVal.Lower_Value__c <= totalRevenue){
                    ratingValId = rRangeVal.Id;
                }
            }
            for(Rating_Matrix_Value__c rMatrixVal : ratingMatrixValues){
                if(ratingValId == rMatrixVal.Rating_Range_Id2__c){
                    RetentionILF optRange = new RetentionILF();
                    String optFactor = rMatrixVal.Factor__c.trim();
                    if(optFactor.left(1) != '{') optFactor = '{' + optFactor;
                    if(!optFactor.endsWith('}')) optFactor += '}';
                    // String optFactor = rMatrixVal.Factor__c.replace('{','').replace('}','');
                    // optFactor = '{' + optFactor + '}';
                    optRange = (RetentionILF)JSON.deserialize(optFactor, RetentionILF.class);
                    listOptRange.add(optRange);
                } 
            }
        }

        return listOptRange;
        
    }

    public static Decimal getStateCountyFactor(String productName, String oppId) {

        Opportunity opp = getOpp(oppId);
        String currState = '';
        String currCounty = '';
        String countyType = '';
        String stateTable = productName == 'EPL' ? 'EPL_State' : 'DO_State';
        String countyTable = productName == 'EPL' ? 'EPL_County' : 'DO_County';
        if(opp != null){
            currState = opp.Account.BillingStateCode;
        }

        Decimal stateRelativityFactor = 1;
        List<Rating_Reference_Name__c> ratingRefNamesState =  
                [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                   (SELECT Rating_Specific_Value_Id__c, Reference_Name_Id__r.Reference_Name__c, 
                    Specific_Value__c, Factor__c, UW_Value__c, Effective_Date__c, 
                    Expiration_Date__c, UW_Code__c, Minimum_Premium__c, Sort_Order__c, State__c 
                    FROM Rating_Specific_Values__r
                    WHERE Specific_Value__c = :currState)   
                FROM Rating_Reference_Name__c Where Reference_Name__c =: stateTable];

        List<Rating_Specific_Value__c> ratingSpecificValues =  ratingRefNamesState[0].Rating_Specific_Values__r;

        if(currState == 'CA' || currState == 'NY'){
            if(opp.Account.Billing_County__c != null){
                currCounty = currState + ' - ' +opp.Account.Billing_County__c;
            }
            else{
                currCounty = 'Missing';
            }

            List<Rating_Reference_Name__c> ratingRefNamesCounty =  
                [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                   (SELECT Rating_Specific_Value_Id__c, Reference_Name_Id__r.Reference_Name__c, 
                    Specific_Value__c, Factor__c, UW_Value__c, Effective_Date__c, 
                    Expiration_Date__c, UW_Code__c, Minimum_Premium__c, Sort_Order__c, State__c 
                    FROM Rating_Specific_Values__r
                    WHERE Specific_Value__c = :currCounty)   
                FROM Rating_Reference_Name__c Where Reference_Name__c =: countyTable];

            List<Rating_Specific_Value__c> ratingSpecificValuesCounty =  ratingRefNamesCounty[0].Rating_Specific_Values__r;
            if(!ratingSpecificValuesCounty.isEmpty()){
                Rating_Specific_Value__c rSpecificVal = ratingSpecificValuesCounty[0];
                if(rSpecificVal.Factor__c != null){
                    countyType = rSpecificVal.Factor__c;
                } 
                else{
                    countyType = 'Low';
                }
            }
            else{
                countyType = 'Low';
            }
            
            if(!ratingSpecificValues.isEmpty()){
                Rating_Specific_Value__c rSpecificVal = ratingSpecificValues[0];
                if(rSpecificVal.Factor__c != null){
                    String optFactor = rSpecificVal.Factor__c;
                    StateRelativityFactorRange relFactorRange = (StateRelativityFactorRange)JSON.deserialize(optFactor, StateRelativityFactorRange.class);
                    if(countyType != null){
                        RelativityFactor relFac = relFactorRange.relativityFactor;
                        if(countyType == 'Low'){
                            stateRelativityFactor = relFac.Low;
                        }
                        else{
                            stateRelativityFactor = relFac.high;
                        }
                    }
                }  
            }

        }
        else{

            if(!ratingSpecificValues.isEmpty()){
                Rating_Specific_Value__c rSpecificVal = ratingSpecificValues[0];
                if(rSpecificVal.Factor__c != null){
                    String optFactor = rSpecificVal.Factor__c;
                    StateRelativityFactor relFactorRange = (StateRelativityFactor)JSON.deserialize(optFactor, StateRelativityFactor.class);
                    stateRelativityFactor = relFactorRange.relativityFactor;
                }  
            }

        }

        return stateRelativityFactor;

    }

    public static  List<RateableEmployeesTable> getRatableEmployeeFactor() {
        
        /*Opportunity opp = getOpp(oppId);
        Decimal ratableEmployees;
        if(opp != null){
            ratableEmployees = Decimal.valueOf(opp.Ratable_Employees__c);
        }*/
        
        Decimal ratableEmployeeFactor;
        List<RateableEmployeesTable> rateableEmployeeFactorList = new List<RateableEmployeesTable>();

        List<Rating_Reference_Name__c> ratingRefNames =  
                [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                (SELECT Rating_Range_Value__c, Reference_Name_Id__r.Reference_Name__c, 
                    Factor__c, Upper_Value__c, Lower_Value__c, Effective_Date__c, 
                    Expiration_Date__c, Minimum_Premium__c FROM Rating_Range_Values__r ) 
                FROM Rating_Reference_Name__c Where Reference_Name__c = 'EPL_RatableEmployees'];
        
        
        List<Rating_Range_Value__c> ratingRangeValues =  ratingRefNames[0].Rating_Range_Values__r;
        
        if(!ratingRangeValues.isEmpty()){
            for(Rating_Range_Value__c rRangeVal : ratingRangeValues){
                RateableEmployeesTable rateableEmployee = new RateableEmployeesTable();
                rateableEmployee.lowerValue = rRangeVal.Lower_Value__c;
                rateableEmployee.upperValue = rRangeVal.Upper_Value__c;
                RateableEmployeeFactor optRange = new RateableEmployeeFactor();
                String optFactor = rRangeVal.Factor__c.trim();
                if(optFactor.left(1) != '{') optFactor = '{' + optFactor;
                if(!optFactor.endsWith('}')) optFactor += '}';
                // String optFactor = rRangeVal.Factor__c.replace('{','').replace('}','');
                // optFactor = '{' + optFactor + '}';
                optRange = (RateableEmployeeFactor)JSON.deserialize(optFactor, RateableEmployeeFactor.class);
                rateableEmployee.rateableEmployeeFactor = optRange;
                rateableEmployeeFactorList.add(rateableEmployee);
                /*Decimal lowerValue = rRangeVal.Lower_Value__c;
                Decimal upperValue = rRangeVal.Upper_Value__c;
                if(ratableEmployees >= lowerValue && ratableEmployees < upperValue){
                    RateableEmployeeFactor optRange = new RateableEmployeeFactor();
                    String optFactor = rRangeVal.Factor__c.replace('{','').replace('}','');
                    optFactor = '{' + optFactor + '}';
                    optRange = (RateableEmployeeFactor)JSON.deserialize(optFactor, RateableEmployeeFactor.class);
                    Integer baseRate = Integer.valueOf(optRange.base_rate);
                    Integer perEmployeeRate = Integer.valueOf(optRange.per_employee_rate);
                    Integer rangeLowerLimit = Integer.valueOf(optRange.range_lower_limit);
                    ratableEmployeeFactor = baseRate + ((ratableEmployees - rangeLowerLimit) * perEmployeeRate);
                }*/
                
            }
        }

        return rateableEmployeeFactorList;
        
    }

    public static Decimal getLimitFactor(Decimal LimitDecimal,List<RatingFactorsHelper.LimitILF> listLimitRange) {

        Decimal limitFactor = 0;
        System.debug('LimitDecimal----->'+LimitDecimal);
        for(RatingFactorsHelper.LimitILF objLimitILF : listLimitRange){
            System.debug('objLimitILF----->'+objLimitILF);
            Decimal lowerBound = Decimal.valueOf(objLimitILF.lowerBound);
            Decimal upperBound = Decimal.valueOf(objLimitILF.upperBound);
            if(lowerBound <= LimitDecimal && upperBound > LimitDecimal){
                if(objLimitILF.lowerFactor != 'N/A' && objLimitILF.upperFactor != 'N/A'){
                    Decimal lowerFactor = Decimal.valueOf(objLimitILF.lowerFactor);
            		Decimal upperFactor = Decimal.valueOf(objLimitILF.upperFactor);
                    if(lowerBound == LimitDecimal){
                        limitfactor = Decimal.valueOf(objLimitILF.lowerFactor);
                    }
                    else{
                        Decimal limitRange = upperBound - lowerBound;
                        Decimal factorRange = upperFactor - lowerFactor;
                        Decimal limitexcess = LimitDecimal - lowerBound;
                        Decimal limitRangePercent = limitexcess/limitRange;
                        limitfactor = lowerFactor + (factorRange*limitRangePercent);
                    }
                }
                else if(objLimitILF.formulaExponent != 'N/A'){
                    Decimal temp = 1000000;
                    limitfactor = Math.pow(Double.valueOf(LimitDecimal / temp ) , (Double.valueOf(objLimitILF.formulaExponent)));
                }
            }
        }

        return limitfactor;

    }

    public static Decimal getRetentionFactor(Decimal retentionDecimal,List<RatingFactorsHelper.RetentionILF> listRetentionMod) {

        Decimal retentionFactor = 0;
        for(RatingFactorsHelper.RetentionILF objRetentionILF : listRetentionMod){
            Decimal LowerValue = Decimal.valueOf(objRetentionILF.LowerValue);
            Decimal UpperValue = Decimal.valueOf(objRetentionILF.UpperValue);
            if(LowerValue <= retentionDecimal && UpperValue > retentionDecimal){
                if(objRetentionILF.lowerFactor != 'N/A' && objRetentionILF.upperFactor != 'N/A'){
                    Decimal lowerFactor = Decimal.valueOf(objRetentionILF.lowerFactor);
            		Decimal upperFactor = Decimal.valueOf(objRetentionILF.upperFactor);
                    if(LowerValue == retentionDecimal){
                        retentionFactor = Decimal.valueOf(objRetentionILF.lowerFactor);
                    }
                    else{
                        Decimal retentionRange = UpperValue - LowerValue;
                        Decimal factorRange = upperFactor - lowerFactor;
                        Decimal retentionexcess = retentionDecimal - LowerValue;
                        Decimal retentionRangePercent = retentionexcess/retentionRange;
                        retentionFactor = lowerFactor + (factorRange*retentionRangePercent);
                    }
                }
            }
        }

        return retentionFactor;

    }

    public static Map<String,List<WageHourFactor>> getWHFactorMap(String productName, String refName) {

        Map<String,List<WageHourFactor>> mapWHFactors = new Map<String,List<WageHourFactor>>();

        List<Rating_Reference_Name__c> ratingRefNames =  
                        [SELECT  Product_Id__c, Rating_Reference_Name_Id__c, Reference_Name__c,
                        (SELECT Rating_Range_Value__c, Reference_Name_Id__r.Reference_Name__c, 
                            Factor__c, Upper_Value__c, Lower_Value__c, Effective_Date__c, 
                            Expiration_Date__c, Minimum_Premium__c FROM Rating_Range_Values__r ) ,
                        (SELECT Rating_Specific_Value_Id__c, Reference_Name_Id__r.Reference_Name__c, 
                            Specific_Value__c, Factor__c, UW_Value__c, Effective_Date__c, 
                            Expiration_Date__c, UW_Code__c, Minimum_Premium__c, Sort_Order__c, State__c 
                            FROM Rating_Specific_Values__r), 
                        (SELECT Name, Reference_Name_Id__r.Reference_Name__c, 
                            Factor__c, Rating_Range_Id__r.Upper_Value__c, Rating_Range_Id__r.Lower_Value__c, Rating_Range_Id2__c,
                            //Rating_Range_Id2__r.Upper_Value__c, Rating_Range_Id2__r.Lower_Value__c, 
                            Effective_Date__c, Expiration_Date__c, Minimum_Premium__c,Rating_Specific_Id__c FROM Rating_Matrix_Value__r)
                        FROM Rating_Reference_Name__c Where Reference_Name__c = :refName];
        
        List<Rating_Specific_Value__c> ratingSpecificValues =  ratingRefNames[0].Rating_Specific_Values__r;
        List<Rating_Range_Value__c> ratingRangeValues =  ratingRefNames[0].Rating_Range_Values__r;
        List<Rating_Matrix_Value__c> ratingMatrixValues =  ratingRefNames[0].Rating_Matrix_Value__r;

        if(!ratingSpecificValues.isEmpty() && !ratingRangeValues.isEmpty() && !ratingMatrixValues.isEmpty()){
            for(Rating_Specific_Value__c objSpecVal : ratingSpecificValues){
                List<WageHourFactor> listWHFactors = new List<WageHourFactor>();
                for(Rating_Range_Value__c objRangeVal : ratingRangeValues){
                    WageHourFactor objWHFactor = new WageHourFactor();
                    objWHFactor.lowerValue = objRangeVal.Lower_Value__c;
                    objWHFactor.upperValue = objRangeVal.Upper_Value__c;
                    for(Rating_Matrix_Value__c objMatVal : ratingMatrixValues){
                        if(objMatVal.Rating_Range_Id__c == objRangeVal.Id && objMatVal.Rating_Specific_Id__c == objSpecVal.Id){
                            WHFactor factorWrapper = (WHFactor)JSON.deserialize(objMatVal.Factor__c, WHFactor.class);
                            objWHFactor.factorValue = objMatVal.Factor__c;
                            objWHFactor.lowerFactor = factorWrapper.lowerFactor;
                            objWHFactor.upperFactor = factorWrapper.upperFactor;
                        }
                    }
                    listWHFactors.add(objWHFactor);
                }
                mapWHFactors.put(objSpecVal.Specific_Value__c, listWHFactors);
            }

        }

        return mapWHFactors;

    }
    
    

     /**
      * Wrapper class for factor range values.
      */
      
     public class FactorRange {      
        @AuraEnabled  
        public string Range_Lower         {get; set;}
        @AuraEnabled
        public string Range_Upper         {get; set;}
        @AuraEnabled
        public string hazard_group         {get; set;}
        public FactorRange() {
            this.Range_Lower = '';
            this.Range_Upper = '';
            this.hazard_group = '';
        }
    }

    public class FactorRangeLowMidHigh {      
        @AuraEnabled  
        public string Low         {get; set;}
        @AuraEnabled
        public string Medium         {get; set;}
        @AuraEnabled
        public string High         {get; set;}
        @AuraEnabled
        public string hazard_group         {get; set;}
        public FactorRangeLowMidHigh() {
            this.Low = '';
            this.Medium = '';
            this.High = '';
            this.hazard_group = '';
        }
    }

    public class FactorRangeFlat {    
        @AuraEnabled
        public string factor         {get; set;}
        @AuraEnabled
        public string hazard_group         {get; set;}
        public FactorRangeFlat() {
            this.factor = '';
            this.hazard_group = '';
        }
    }
    
    public class StateRange { 
        @AuraEnabled       
        public string maxDebit         {get; set;}
        @AuraEnabled
        public string maxCredit         {get; set;}
        @AuraEnabled
        public string commAdjMin         {get; set;}
        @AuraEnabled
        public string commAdjMax         {get; set;}
        @AuraEnabled
        public string targetCommission         {get; set;}
        public StateRange() {
            this.maxDebit = '';
            this.maxCredit = '';
            this.commAdjMin = '';
            this.commAdjMax = '';
            this.targetCommission = '';
        }
    }

    public class LimitILF { 
        @AuraEnabled       
        public string lowerBound         {get; set;}
        @AuraEnabled
        public string upperBound         {get; set;}
        @AuraEnabled
        public string lowerFactor         {get; set;}
        @AuraEnabled
        public string upperFactor         {get; set;}
        @AuraEnabled
        public string formulaExponent        {get; set;}
        public LimitILF() {
            this.lowerBound = '';
            this.upperBound = '';
            this.lowerFactor = '';
            this.upperFactor = '';
            this.formulaExponent = '';
        }
    }

    public class LimitILFEPL { 
        @AuraEnabled       
        public string lower_limit         {get; set;}
        @AuraEnabled
        public string upper_limit         {get; set;}
        @AuraEnabled
        public string lower_factor         {get; set;}
        @AuraEnabled
        public string upper_factor         {get; set;}
        @AuraEnabled
        public string calculate_factor        {get; set;}
        public LimitILFEPL() {
            this.lower_limit = '';
            this.upper_limit = '';
            this.lower_factor = '';
            this.upper_factor = '';
            this.calculate_factor = '';
        }
    }

    public class RateableEmployeesTable { 
        @AuraEnabled       
        public Decimal lowerValue         {get; set;}
        @AuraEnabled
        public Decimal upperValue       {get; set;}
        @AuraEnabled
        public RateableEmployeeFactor rateableEmployeeFactor         {get; set;}
        public RateableEmployeesTable() {
            this.lowerValue = 0;
            this.upperValue = 0;
            this.rateableEmployeeFactor = new RateableEmployeeFactor();
        }
    }

    public class RateableEmployeeFactor { 
        @AuraEnabled       
        public string base_rate         {get; set;}
        @AuraEnabled
        public string per_employee_rate       {get; set;}
        @AuraEnabled
        public string range_lower_limit         {get; set;}
        public RateableEmployeeFactor() {
            this.base_rate = '';
            this.per_employee_rate = '';
            this.range_lower_limit = '';
        }
    }

    public class RetentionILF { 
        @AuraEnabled       
        public string LowerValue         {get; set;}
        @AuraEnabled
        public string UpperValue         {get; set;}
        @AuraEnabled
        public string lowerFactor         {get; set;}
        @AuraEnabled
        public string upperFactor         {get; set;}
        public RetentionILF() {
            this.LowerValue = '';
            this.UpperValue = '';
            this.lowerFactor = '';
            this.upperFactor = '';
        }
    }

    public class WHFactor { 
        @AuraEnabled       
        public Decimal LowerValue         {get; set;}
        @AuraEnabled
        public Decimal UpperValue         {get; set;}
        @AuraEnabled
        public Decimal LowerFactor         {get; set;}
        @AuraEnabled
        public Decimal UpperFactor         {get; set;}
        public WHFactor() {
            this.LowerValue = 0;
            this.UpperValue = 0;
            this.lowerFactor = 0;
            this.upperFactor = 0;
        }
    }

    public class StateRelativityFactor {      
        @AuraEnabled  
        public Decimal relativityFactor      {get; set;}
        public StateRelativityFactor() {
            this.relativityFactor = 1;
        }
    }

    public class StateRelativityFactorRange {      
        @AuraEnabled  
        public RelativityFactor relativityFactor      {get; set;}
        public StateRelativityFactorRange() {
            this.relativityFactor = new RelativityFactor();
        }
    }

    public class RelativityFactor {      
        @AuraEnabled  
        public Decimal high      {get; set;}
        @AuraEnabled  
        public Decimal Low      {get; set;}
        public RelativityFactor() {
            this.high = 1;
            this.Low = 1;
        }
    }

    public class WageHourFactor{

        @AuraEnabled
        public Decimal lowerValue {get; set;}
        @AuraEnabled
        public Decimal upperValue {get; set;}
        @AuraEnabled
        public Decimal lowerFactor {get; set;}
        @AuraEnabled
        public Decimal upperFactor {get; set;}
        @AuraEnabled
        public String factorValue {get; set;}
        public WageHourFactor() {
            this.lowerValue = 0;
            this.upperValue = 0;
            this.factorValue = '';
        }

    }
    
}