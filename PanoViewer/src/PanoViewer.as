package 
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.system.System;
	
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	
	import org.billbsb.as3.panomax.Panomax;
	
	[SWF(width = "1400", height = "600", frameRate = "1", backgroundColor = "#000000", pageTitle = "PanoViewer")]
	public class PanoViewer extends Sprite 
	{
		// Huge panorama image embeded with the SWF
		[Embed(source = 'london-pano.jpg')]
		private var panoClass:Class;
		
		// Numeric code for determining what is the current image displayed
		private var currentImage:uint;
		private var currentBitmap:Bitmap;
		private var panoMax:Panomax;
		private var imageLoader:CachingImageLoader;
		
		private var statusDisplay:TextField;
		
		// Must match the SWF tag. We use this to avoid bugs when the .swf is displayed on the index.html file
		private var swfWidth:int;
		private var swfHeight:int;
		
		public function PanoViewer():void 
		{
			// Code inside constructor cannot be optimised. Avoid putting a lot stuff on your constructors.
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		protected function init(e:Event = null):void 
		{
			trace("[PanoViewer.init] stage.stageWidth: " + stage.stageWidth + ", stage.stageHeight: "+stage.stageHeight);
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			// Show the embeded image first
			currentBitmap = new panoClass();
			currentImage = 0;
			
			// Must match the SWF tag. We use this to avoid bugs when the .swf is displayed on the index.html file
			swfWidth = 1400;
			swfHeight = 600;
			
			stage.scaleMode =  StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.quality = StageQuality.LOW;
			
			if (statusDisplay == null) {
				statusDisplay = new TextField();
				statusDisplay.defaultTextFormat = new TextFormat('Verdana',14, 0x00ff00);
				statusDisplay.autoSize = TextFieldAutoSize.LEFT;
				statusDisplay.x = 10;
				statusDisplay.y = 10;
				statusDisplay.selectable = false;
			}
			
			imageLoader = new CachingImageLoader();
			imageLoader.addEventListener(Event.COMPLETE, completeHandler);
			imageLoader.addEventListener(IOErrorEvent.IO_ERROR,loadingError);
			
			initPanomax()
			
			createCTA();
			
			this.addChild(statusDisplay);
		}
		
		private function loadingError(evt:IOErrorEvent):void
		{
			trace("[PanoViewer.loadingError]  evt: " + evt.toString());
			this.statusDisplay.text = evt.toString();
		}
		
		/**
		 * Initializes the parameters for PanoMax, creates an instance of Panomax and add it to the stage.
		 */
		private function initPanomax():void{
			var params:Object = {
				width: swfWidth
				,height: swfHeight
				,bitmap: currentBitmap
				,isCentered: true
				,isHoverScroll: true
				,isLinear: false
				,loopMode: "x"
				,frameMS: 17
			};
			
			panoMax = new Panomax(params);
			
			addChildAt(panoMax,0);
			
			trace("[PanoViewer.initPanomax] privateMemory: " + System.privateMemory / 1024);
		}
		
		/**
		 * Initializes the parameters for CTAButton, creates an instance of CTAButton and add it to the stage.
		 */
		private function createCTA():void
		{
			trace("[PanoViewer.createCTA]");
			var params:Object = {
				label:"Change Panorama Image",
				x: swfWidth / 2,	// Show the button in the middle of the stage
				y: swfHeight / 2,
				bkgColor:0x000000, 
				overColor:0xFFFFFF, 
				fontColor:0xFFFFFF,
				fontSize: 18,
				url: "http://www.magicbullet.nl",
				clickHandler: ctaClickHandler
			};
			
			stage.addChild(new CTAButton(params));
		}
		
		/**
		 * Updates the currentImage variable, uses the imageLoader to load external images
		 * @param	event
		 */
		private function ctaClickHandler(event:MouseEvent):void
		{
			trace("[PanoViewer.ctaClickHandler] currentImage: " + currentImage);
			currentImage++;
			this.statusDisplay.text = "loading... " + currentImage;
			switch(currentImage){
				case 1:
					imageLoader.loadImage("http://williamrjribeiro.com/demos/tour_eiffel_360_panorama.jpg");
					break;
				case 2:
					imageLoader.loadImage("http://upload.wikimedia.org/wikipedia/commons/6/65/SonyCenter_360panorama.jpg");
					break;
				case 3:
					imageLoader.loadImage("http://upload.wikimedia.org/wikipedia/commons/c/cf/Panorama_360_Lac_de_Joux.jpg");
					break;
				case 4:
					// Start from the beginning with the embeded image.
					currentImage = 0;
					currentBitmap = new panoClass();
					completeHandler(null);
					break;
			}
			
		}
		
		private function completeHandler(evt:Event):void
		{
			trace("[PanoViewer.completeHandler] currentImage: " + currentImage + ", evt: " + evt);
			this.statusDisplay.text = "";
			removeChild(panoMax);
			if(evt != null)
				currentBitmap = imageLoader.currentBitmap;
			initPanomax();
		}
	}
	
}