public class Warnings {
    public virtual class BaseException extends Exception {}
    public virtual class RatingException extends BaseException {}
    public class ProductMapException extends RatingException {}
    public class LimitDeductibleException extends RatingException {}
    public class SubCoverageMapException extends RatingException {}
}