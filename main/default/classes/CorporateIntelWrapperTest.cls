@isTest
public class CorporateIntelWrapperTest {
    
    @isTest
    static void corporateWrapperTest(){
        Test.startTest();
        
        List<CorporateIntelWrapper.IndustryCodes> newIndustryCodes = new List<CorporateIntelWrapper.IndustryCodes>();
        CorporateIntelWrapper.IndustryCodes industryCode = new CorporateIntelWrapper.IndustryCodes();
            industryCode.code = 'Test 123';				
            industryCode.typeDescription 	= 'Test Description';				
            industryCode.typeDnBCode = 'Test DnBCode';
        newIndustryCodes.add(industryCode);
        
        List<CorporateIntelWrapper.JobTitles> newJobTitles = new List<CorporateIntelWrapper.JobTitles>();
        CorporateIntelWrapper.JobTitles jobTitle = new CorporateIntelWrapper.JobTitles();
            jobTitle.title = 'Engineer';
        newJobTitles.add(jobTitle);
        
        List<CorporateIntelWrapper.MostSeniorPrincipals> newSeniorPrincipals = new List<CorporateIntelWrapper.MostSeniorPrincipals>();
        CorporateIntelWrapper.MostSeniorPrincipals seniorPrincipals = new CorporateIntelWrapper.MostSeniorPrincipals();
            seniorPrincipals.jobTitles = newJobTitles;
        newSeniorPrincipals.add(seniorPrincipals);
        
        List<CorporateIntelWrapper.RatingReason> newRatingReasons = new List<CorporateIntelWrapper.RatingReason>();        
        CorporateIntelWrapper.RatingReason newRatingReason = new CorporateIntelWrapper.RatingReason();
            newRatingReason.description = 'Test Rating Reason';
        newRatingReasons.add(newRatingReason);
        
        CorporateIntelWrapper.StandardRating newStandardRating = new CorporateIntelWrapper.StandardRating();
        newStandardRating.rating = '5';
        newStandardRating.ratingReason = newRatingReasons;
        
        CorporateIntelWrapper.DnBAssessment newDnBAssessment = new CorporateIntelWrapper.DnBAssessment();
        newDnBAssessment.standardRating = newStandardRating;
        
        CorporateIntelWrapper.overview newOverview = new CorporateIntelWrapper.overview();
            newOverview.salesRevenue = 1000000.00;
            newOverview.netWorth = 500000000L;
            newOverview.totalCurrentAssets = 500000000L;
            newOverview.totalAssets = 500000000L;
            newOverview.totalCurrentLiabilities = 500000000L;
            newOverview.totalLiabilities = 500000000L;
            newOverview.longTermDebt = 'longTermDebt';
            newOverview.retainedEarnings = 'retainedEarnings';
            newOverview.netIncome = 500000000L; 
            
        CorporateIntelWrapper.latestFinancials newLatestFinancials = new CorporateIntelWrapper.latestFinancials();    
        	newLatestFinancials.overview = newOverview;
        	newLatestFinancials.financialStatementFromDate = '01-01-2021';
        	newLatestFinancials.financialStatementToDate =  '31-12-2021';
        
        CorporateIntelWrapper.organization newOrganization = new CorporateIntelWrapper.organization();
            newOrganization.latestFinancials = newLatestFinancials;
            newOrganization.incorporatedDate = '01-01-2021';
            newOrganization.dnbassessment = newDnBAssessment;
            newOrganization.mostSeniorPrincipals = newSeniorPrincipals;
            newOrganization.industryCodes = newIndustryCodes;
        
        CorporateIntelWrapper.corporateWrapper newCorporateWrapper = new CorporateIntelWrapper.corporateWrapper();
        newCorporateWrapper.organization = newOrganization;
							
        Test.stopTest();
        
        System.assert(newCorporateWrapper != null);
    }
}