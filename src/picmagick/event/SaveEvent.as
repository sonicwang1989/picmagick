package picmagick.event
{
	import flash.events.Event;
	
	public class SaveEvent extends Event
	{
		private var m_Quality:int;
		private var m_FileType:String;
		
		public function SaveEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public function get Quality():int{
			return m_Quality;
		}
		
		public function set Quality(val:int):void{
			m_Quality=val;
		}
		
		public function get FileType():String{
			return m_FileType;
		}
		
		public function set FileType(val:String):void{
			m_FileType=val;
		}
	}
}