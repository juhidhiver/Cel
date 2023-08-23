public class CorporateIntelWrapper {

    public class corporateWrapper {
        public organization organization;
        
    }
    public class organization {
        public latestFinancials latestFinancials ;
        public string incorporatedDate {get; set;}
        public DnBAssessment dnbassessment;
        public List <MostSeniorPrincipals> mostSeniorPrincipals;
        public List <IndustryCodes> industryCodes;
    }
    public class latestFinancials{
        public overview overview ;
        public String financialStatementFromDate {get; set;}
        public String financialStatementToDate {get; set;}
    }
    public class overview{
        public Decimal salesRevenue {get; set;}
        public Long netWorth {get; set;}
        public Decimal totalCurrentAssets {get; set;}
        public Decimal totalAssets {get; set;}
        public Decimal totalCurrentLiabilities {get; set;}
        public Decimal totalLiabilities {get; set;}
        public string longTermDebt {get; set;}
        public string retainedEarnings {get; set;}
        public Decimal netIncome {get; set;}
    }
    public class DnBAssessment{
        public StandardRating standardRating;
    }
    public class StandardRating{
        public String rating {get; set;}
        public List <RatingReason> ratingReason {get; set;}
    }
    public class RatingReason{
         public String description {get; set;}
    }
    public class MostSeniorPrincipals{
        public List<JobTitles> jobTitles {get; set;}
    }
    public class JobTitles{
        public String title {get; set;}
    }
    public class IndustryCodes{
        public String code {get; set;}
        public String typeDescription {get; set;}
        public String typeDnBCode {get; set;}
    }
    
}