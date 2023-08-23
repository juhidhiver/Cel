public class SessionIdController {
  public static String getSessionId() {
    try {
      return Page.TestApi.getContent().toString(); 
    } catch (Exception ex) {
      return '';
    }
  }
}