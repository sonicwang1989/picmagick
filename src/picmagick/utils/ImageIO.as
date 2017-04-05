package picmagick.utils {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import by.blooddy.crypto.image.JPEGEncoder;
	import by.blooddy.crypto.image.PNG24Encoder;
	
	// utility class to load/save image (JPEG/PNG) files
	public class ImageIO extends EventDispatcher {
		/*
		 *JPEG encoder, imported from jpegencoder_10092010.swc
		 *http://segfaultlabs.com/devlogs/alchemy-asynchronous-jpeg-encoding-2 
		*/
		private var _beginLoad:Function;//callback function after image begin load
		private var _imageLoading:Function;//callback function when image loading
		private var _endLoad:Function;//callback function after image loaded complete
		private var _imageLoaded:Function; // callback function after image is loaded, takes one parameter BitmapData
		private var _imageSaved:Function; // callback function after image is saved, takes no parameters
		private var _ioError:Function; // callback function after io error occurs, takes no parameter
		private var _onError:Function; // callback function after error occurs, takes no parameter
		private var _imageDimLimit:int = 10000; // image dimension limit, default to 10000 x 10000
		private var _filename:String; // current image filename
		private var _serverUrl:String;//server that image to be sende to url 
		private var _quality:int;
		private var _fileType:String;
		private var _proxyService:String;//Proxy Service for cross domain
		private var _domain:String;//current domain
		private var _oldUrl:String;
		private var _newUrl:String;
		
		public function ImageIO(beginLoad:Function,imageLoading:Function,endLoad:Function, imageLoaded:Function, imageSaved:Function, ioError:Function,onError:Function) {
			_beginLoad=beginLoad;
			_imageLoading=imageLoading;
			_endLoad=endLoad;
			_imageLoaded = imageLoaded;
			_imageSaved = imageSaved;
			_ioError = ioError;
			_onError=onError;
		}	
		
		public function set ServerUrl(url:String):void
		{
			_serverUrl=url;
		}
		
		public function get ServerUrl():String
		{
			return _serverUrl;
		}
		
		public function set Quality(quality:int):void
		{
			_quality=quality;
		}
		
		public function get Quality():int
		{
			return _quality;
		}
		
		public function set FileType(type:String):void
		{
			_fileType=type;
			_filename="image."+type;
		}
		
		public function get FileType():String
		{
			return _fileType;
		}
		
		public function set ProxyService(url:String):void
		{
			_proxyService=url;
		}
		
		public function get ProxyService():String
		{
			return _proxyService;
		}
		
		public function set Domain(domain:String):void{
			_domain=domain.toLowerCase();
		}
		
		// set image dimension limit (dim x dim), default to 2048 x 2048
		public function set imageDimLimit(dim:int):void {
			_imageDimLimit = dim;
		}
		
		// load image, _imageLoaded(BitmapData) will be called after completion
		public function loadImage():void {
			var fileRef:FileReference = new FileReference()
			var fileTypes:FileFilter = new FileFilter("Photo File (*.jpg, *.jpeg, *.png)", "*.jpg; *.jpeg; *.png;");
			fileRef.addEventListener(Event.SELECT, function (event:Event):void { getFileExten(fileRef.name ); beginLoad(event);fileRef.load(); });
			fileRef.addEventListener(Event.COMPLETE, fileLoaded);
			fileRef.addEventListener(IOErrorEvent.IO_ERROR, function (event:Event):void { _ioError(); });
			fileRef.browse([fileTypes]);
		}
		
		public function loadImageFromUrl(url:String):void{
			try
			{
				if(isCrossDomain(url))
				{
					_oldUrl=url;
					var service:HTTPService=new HTTPService();
					service.url=_proxyService;
					service.method="POST";
					service.showBusyCursor=true;
					service.useProxy=false;
					//service.resultFormat="e4x";
					service.addEventListener(ResultEvent.RESULT,function(event:ResultEvent):void{
						if(event.result!=null&&event.statusCode==200){
							var json:Object=JSON.parse(String(event.result.string));
							url=json.NewUrl;
							loadImageFromUrl(url);
						}
						else{
							_onError(new Error("This image is not exists!"));
						}
					});
					service.send({"url":url});
					return;
				}
				_newUrl=url;
				var loader:Loader=new Loader();
				var urlRequest:URLRequest=new URLRequest(url);
				var loaderContext:LoaderContext=new LoaderContext();
				loaderContext.checkPolicyFile=true;
				loader.contentLoaderInfo.addEventListener(Event.OPEN,function(event:Event):void{ getFileExten(url);beginLoad(event);} );
				loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,imageLoading);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,endLoad);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,imageLoaded);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function (event:Event):void { _ioError(); });
				loader.load(urlRequest,loaderContext);	
			} 
			catch(error:Error) 
			{
				_onError(error);
			}
		}
		
		// save image from BitmapData, _imageSaved() will be called after completion
		public function saveImage(bitmapData:BitmapData):void {
			var bytes:ByteArray=getByteArray(bitmapData);
			var fileRef:FileReference = new FileReference();
			fileRef.addEventListener(Event.COMPLETE, fileSaved);
			fileRef.save(bytes, _filename);
		}
		
		//send this image to server
		public function saveImageToServer(bitmapData:BitmapData):void{
			dispatchEvent(new Event("BeginUploadEvent"));
			var requestUrl:String=ServerUrl;
			if(ServerUrl.indexOf("?")==-1){
				requestUrl+="?old="+encodeURI(_oldUrl)+"&new="+encodeURI( _newUrl)+"&type="+_fileType;
			}
			else{
				requestUrl+="&old="+encodeURI(_oldUrl)+"&new="+encodeURI( _newUrl)+"&type="+_fileType;
			}
			
			var loader:URLLoader=new URLLoader();
			var request:URLRequest=new URLRequest(requestUrl);
			loader.dataFormat=URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE,function(event:Event):void{
				fileSaved(event);
				dispatchEvent(new Event("UploadFinishedEvent"));
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR,function (event:Event):void { _ioError(event); });
			request.method=URLRequestMethod.POST;
			request.data= getByteArray(bitmapData);
			request.contentType="application/octet-stream";
			loader.load(request);
		}
		
		//file selected
		private function getFileExten(name:String):void{
			var filename:String=name.toLocaleLowerCase();
			if(filename.indexOf(".jpg")!=-1||filename.indexOf(".jpeg")!=-1)
			{
				_fileType="jpg";
			}
			else if(filename.indexOf(".png")!=-1)
			{
				_fileType="png";
			}
			_filename="image."+_fileType;
		}
		
		//begin load image
		private function beginLoad(event:Event):void{
			_beginLoad(event);
		}
		
		//loading image
		private function imageLoading(event:Event):void{
			_imageLoading(event);
		}
		
		//load image complete
		private function endLoad(event:Event):void{
			_endLoad(event);
		}
		
		// (event handler) file is selected
		private function fileLoaded(event:Event):void {
			var fileRef:FileReference = event.target as FileReference;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,imageLoading);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,endLoad);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function (event:Event):void { _ioError(); });
			loader.loadBytes(fileRef.data);
		}

		// (event handler) file is loaded
		private function imageLoaded(event:Event):void {
			var loaderInfo:LoaderInfo = event.target as LoaderInfo;
			try
			{
				var bitmapData:BitmapData = (loaderInfo.content as Bitmap).bitmapData;
				_imageLoaded(resize(bitmapData, _imageDimLimit));
			} 
			catch(error:Error) 
			{
				_onError(error);
			}
		}
		
		// (event handler) file is saved
		private function fileSaved(event:Event):void {
			if(event.target is FileReference){
				_imageSaved();
			}
			else if( event.target is URLLoader){
				var loader:URLLoader=event.target as URLLoader;
				if(loader.data!=null){
					var result:String=loader.data;
					var json:Object=JSON.parse(result);
					if(json.Success){
						_imageSaved(json);
					}else{
						_onError(new Error(json.Message));
					}
				}	
			}
		}
		
		// reduce image size to dim x dim, keeping aspect
		private function resize(input:BitmapData, dim:int):BitmapData {
			var w:int;
			var h:int;
			if (input.width > input.height) {
				if (input.width > dim) {
					w = dim;
					h = dim / input.width * input.height;
				} else {
					w = input.width;
					h = input.height;
				}
			} else {
				if (input.height > dim) {
					w = dim / input.height * input.width;
					h = dim;
				} else {
					w = input.width;
					h = input.height;
				}
			}
			var ret:BitmapData = new BitmapData(w, h);
			var s:Number = w / input.width;
			var matrix:Matrix = new Matrix();
			matrix.scale(s, s);
			ret.draw(input, matrix);
			return ret;
		}
		
		//get bytes of bitmap
		private function getByteArray(bitmap:BitmapData):ByteArray
		{
			if(bitmap==null){
				return null;
			}
			var encoderBytes:ByteArray=new ByteArray();
			if(this.FileType=="jpg"){
				//var bytes:ByteArray=bitmap.getPixels(bitmap.rect);
				//bytes.position=0;
				//jpegEncoder.encode(bytes,encoderBytes,bitmap.width,bitmap.height,_quality);
				encoderBytes=JPEGEncoder.encode(bitmap,_quality);
			}
			else if(this.FileType=="png"){
				encoderBytes=PNG24Encoder.encode(bitmap);
			}
			return encoderBytes;
		}
		
		//whether this url cross domain
		private function isCrossDomain(url:String):Boolean
		{
			if(url.toLowerCase().indexOf(_domain)==-1)
			{
				return true;
			}
			return false;
		}
	}
}