package picmagick.event
{
	public class SaveToServerEvent extends SaveEvent
	{
		public function SaveToServerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}