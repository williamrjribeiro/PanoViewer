package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	/**
	 * Simple class for loading images asynchronously from the internet. It try to handle crossdomain issues,
	 * but it all depends on external crossdomain.xml where the image is hosted.
	 * It has a very simple caching mechanism.
	 * It doesn't handle any errors at all.
	 */
	public class CachingImageLoader extends EventDispatcher
	{
		/**
		 * The Bitmap that is currently loaded and ready to be used. Read-only.
		 */
		private var _currentBitmap:Bitmap;
		
		/**
		 * Used for caching loaded Bitmaps. Only created if caching is true. Read-only.
		 * key: Image URL specified on loadImage() OR temporary Byte Loader
		 * value: the Bitmap object OR image URL associated with the Byte Loader
		 */
		protected var cache:Dictionary;
		
		
		/**
		 * Simple class for loading images asynchronously from the internet without raising Security Sandbox Violation warnings.
	 	 * It doesn't handle any errors at all.
		 * @param caching - Flag to enable image caching. Defaults to true. It can't be changed once set.
		 */
		public function CachingImageLoader(caching:Boolean = true)
		{
			trace("[CachingImageLoader] caching: " + caching);
			if(caching)
				cache = new Dictionary(true);
		}
		
		/**
		 * Asynchronously loads the image file specified in the given URL. It doesn't handle any errors. This object dispatches Event.COMPLETE once loading is done.
		 * @param URL - MUST be an URL to an image file.
		 */
		public function loadImage(url:String):void
		{
			trace("[CachingImageLoader.loadImage] url: " + url);
			
			if(cache){
				if (cache[url]) {
					trace("[CachingImageLoader.loadImage] using image cache.");
					_currentBitmap = cache[url];
					dispatchEvent(new Event(Event.COMPLETE));
					return;
				}
			}
			var req:URLRequest = new URLRequest(url);
			var _picLoader:Loader = new Loader();
			var loader_context:LoaderContext = new LoaderContext(true);
			
			if (Security.sandboxType != 'localTrusted')
				loader_context.securityDomain = SecurityDomain.currentDomain;
			loader_context.applicationDomain = ApplicationDomain.currentDomain;
			
			_picLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
			_picLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			_picLoader.load(req, loader_context);
		}
		
		public function clearCache():void
		{
			trace("[CachingImageLoader.clearCache] cache: " + cache);
			if(cache != null)
				cache = new Dictionary(true);
		}
		
		/**
		 * Once the image has been loaded the trick is to NOT touch it's contents. We must work only with its bytes.
		 * @param evt - Event.COMPLETE dispatched by the Loader that loads the URLRequest with given URL
		 */
		private function completeHandler(evt:Event):void
		{
			var lInfo:LoaderInfo = LoaderInfo(evt.target);
			lInfo.removeEventListener(Event.COMPLETE, completeHandler);
			lInfo.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			trace("[CachingImageLoader.completeHandler] lInfo.loaderURL: " + lInfo.url);
			
			var bmd:BitmapData = new BitmapData(lInfo.width, lInfo.height);
			bmd.draw(lInfo.loader);
			_currentBitmap = new Bitmap(bmd);
			
			if(cache){
				cache[lInfo.url] = _currentBitmap;
			}
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 * The Bitmap that is currently loaded and ready to be used. Read-only.
		 */
		public function get currentBitmap():Bitmap
		{
			return _currentBitmap;
		}
		
		private function errorHandler(evt:IOErrorEvent):void
		{
			dispatchEvent(evt.clone());
		}
	}
}