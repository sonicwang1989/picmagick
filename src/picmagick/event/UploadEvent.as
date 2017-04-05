package picmagick.event
{
	import flash.events.Event;
	
	public class BeginUploadEvent extends Event
	{
		public function BeginUploadEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
	
	public class UploadFinishedEvent extends Event
	{
		public function UploadFinishedEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}