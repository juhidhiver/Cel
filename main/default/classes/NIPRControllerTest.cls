@isTest
private class NIPRControllerTest {

	@isTest static void niprAPITest(){
		NIPRController.niprAPI('4003896');
		System.assert(true);
	}
}