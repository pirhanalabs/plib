package plib.userdata;

enum UserDataResult
{
	Failure;
	NotSupported;
	BrowserNotEnabled;
	Success;
	SuccessContent(data:Dynamic);
	FailureReason(reason:String, message:String);
}