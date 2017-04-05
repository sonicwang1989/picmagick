package picmagick.event
{
	public class SaveToLocalEvent extends SaveEvent
	{
		public function SaveToLocalEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}