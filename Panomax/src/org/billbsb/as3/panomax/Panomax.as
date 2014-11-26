package org.billbsb.as3.panomax
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	public class Panomax extends Sprite
	{
 		public var isLinear:Boolean;
		public var isCentered:Boolean;
		public var isHoverScroll:Boolean;
		public var loopMode:String = "x";
		public var factor:Number = 0.01;
		public var params:Object;
		
		// Speed at which to scroll the canvasBD;
		protected var speedX:Number;
		protected var speedY:Number;
		
		// midpoint of the screen. Saved as variable to improve speed;
		protected var midX:Number;
		protected var midY:Number;
		
		// global matrix translations. always acumulates
		protected var gTx:Number;
		protected var gTy:Number;
		
		// The giant image. Just parts of it will be drawn at any given time
		protected var giantImg:Bitmap;
		
		// It's like a canvas used to draw parts of the giant image.
		protected var canvasBD:BitmapData;
		
		// The timer that drives it all; We don't rely on the default Stage Framerate
		protected var updateTimer:Timer;
		
		// The duration in milliseconds of every frame. 16 ms ~= 60fps.
		protected var frameMS:Number;
		
		/**
		 * The matrixes are used for translating the image for rendering. This is the main matrix.
		 * The Bitmap is always static on the display list.
		 */
		protected var matrixA:Matrix;
		
		/**
		 * matrixB is created only if looping is enabled. This is a secondary matrix.
		 * It's the same image with different parts drawn on the canvas only when needed.
		 */
		protected var matrixB:Matrix;
		
		// values to prevent the matrix from moving outside the bitmap;
		private var xLimit:Number;
		private var yLimit:Number;
		private var giWidth:Number;
		
		private var tlGtx:TextField;
		private var tlGty:TextField;
		private var xLimitLeft:Number;
		private var xLimitRight:Number;
		
		private var w:Number;
		private var h:Number;
		private var period:Number;
		
		/**
		 * Scrolls giant images smooooothly and can even loop around horizontally.
		 * @param	params - A generic Object. Available options:
		 * 				width:Number - the width of the canvas
		 * 				height:Number - the height of the canvas
		 * 				bitmap:Bitmap - the panorama image
		 * 				frameMS:Number - the duration in milliseconds of every frame. 16 ms ~= 60fps.
		 * 				isCentered:Boolean - if true the panorama image is displayed on its midle, else its on the top left
		 * 				isLinear:Boolean - if true the image scrolls at constant speed rates, else its at cubic speeds
		 * 				isHoverScroll:Boolean - TODO
		 * 				loopMode:String - "none" will not loop, "x" will loop horizontaly
		 */
		public function Panomax(params:Object)
		{
			super();
			this.params = params;
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		protected function init(e:Event = null):void
		{
			
			removeEventListener(Event.ADDED_TO_STAGE, init);
			addEventListener(Event.REMOVED_FROM_STAGE, detroy);
			
			this.speedX = 0;
			this.speedY = 0;
			
			this.w = params.width as Number;
			this.h = params.height as Number;
			this.giantImg = params.bitmap as Bitmap;
			this.isCentered = params.isCentered as Boolean;
			this.isLinear = params.isLinear as Boolean;
			this.isHoverScroll = params.isHoverScroll as Boolean;
			this.loopMode = params.loopMode as String;
			this.frameMS = params.frameMS as Number;
			
			// create limits
			midX = this.w / 2;
			midY = this.h / 2;
			giWidth = giantImg.width;
			xLimit = this.w - giWidth;
			xLimitLeft = - giWidth;
			xLimitRight = this.w;
			yLimit = this.h - giantImg.height;
			period = giWidth + (2 * this.w)
			trace("[Panomax.init] midX: "+midX+", midY: "+midY+", xLimitLeft: "+xLimitLeft+", xLimitRight: "+xLimitRight+", period: "+period);
			
			// create the canvas to with specified size (change background color for debuging)
			canvasBD = new BitmapData(this.w, this.h, false, 0x000000);
			
			// A new Bitmap is needed for rendering the BitmapData
			var canvasBitmap:Bitmap = new Bitmap(canvasBD, "never");
			addChild(canvasBitmap);
			
			// Create the matrix transformation and set it to middle of giantImg;
			if(isCentered){
				gTx = (this.w * .5) - (giWidth * 0.5);
				gTy = (this.h * .5) - (giantImg.height * 0.5);
			}
			else
				gTx = gTy = 0;
			
			matrixA = new Matrix();
			matrixA.tx = gTx;
			matrixA.ty = gTy;
			
			// create and start the timer loop;
			updateTimer = new Timer(frameMS); // Use our own timer instead of framerate timers. This is much smoother!!!
			switch(this.loopMode){
				case "none":
					updateTimer.addEventListener(TimerEvent.TIMER, onTimerNoLoop);
					break;
				case "x":
					matrixB = new Matrix();
					matrixB.tx = xLimitRight + 1;
					matrixB.ty = matrixA.ty;
					updateTimer.addEventListener(TimerEvent.TIMER, onTimerXLoop);
					break;
			}
			
			// Use this for debugging the Global Transform X/Y (gTx,gTy)
			// createGTXDisplay();
			
			updateTimer.start();
		}
		
		protected function detroy(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			updateTimer.stop()
			updateTimer.removeEventListener(TimerEvent.TIMER, onTimerNoLoop);
			updateTimer = null;
			
			canvasBD.dispose();
			canvasBD = null;
			giantImg = null;
			params = null;
			
			removeEventListener(Event.REMOVED_FROM_STAGE, detroy);
		}
		
		protected function calculateSpeed():void
		{
			// let's tweak the moving speed a little
			speedX = (midX - mouseX) * factor;
			speedY = (midY - mouseY) * factor;
			
			if(!isLinear){
				// cubed values to keep sign
				speedX = speedX * speedX * speedX;
				speedY = speedY * speedY * speedY;;
			}
			//trace("[calculateSpeed] speedX: "+speedX+", speedY: "+speedY);
		}
		
		protected function onTimerNoLoop(e:TimerEvent):void
		{
			// trace("[onTimerNoLoop] mouseX: "+mouseX+", mouseY: "+mouseY);
			calculateSpeed();
			matrixA.translate(speedX, speedY);
			// reset matrix transforms if matrix is out of bounds.
			if (matrixA.tx > 0) {
				matrixA.tx = 0;
			} else if ( matrixA.tx < xLimit) {
				matrixA.tx = xLimit;
			}
			if (matrixA.ty > 0) { 
				matrixA.ty = 0;
			} else if ( matrixA.ty < yLimit) {
				matrixA.ty = yLimit;
			}
			canvasBD.draw(giantImg, matrixA);
			e.updateAfterEvent(); // for immediate rendering!
		}
		
		protected function onTimerXLoop(e:TimerEvent):void 
		{
			// trace("[onTimerXLoop] mouseX: "+mouseX+", mouseY: "+mouseY);
			calculateSpeed();
			
			gTx += speedX;
			gTy += speedY;
			
			// The rendering is periodic so we can rely on the first values. Also avoid Number overflow.
			if(gTx < xLimitLeft)
				gTx = 0; 				// Scrolled all the way to Left, must appear on the Right side
			else if(gTx > xLimitRight)
				gTx = xLimit;			// Scrolled all the way to Right, must appear on the Left side
			
			// No Y-axis looping on this mode
			if (gTy > 0)
				gTy = 0;
			else if ( gTy < yLimit)
				gTy = yLimit;
			
			if(tlGtx && tlGty){
				tlGtx.text = gTx.toFixed(2);
				tlGty.text = gTy.toFixed(2);
			}
			
			var tx:Number = gTx;
			matrixA.ty = matrixB.ty = gTy;
			
			// Since the rendering is periodic, we can convert the global transformation to a previous  value
			if ( tx <= xLimitLeft || tx >= xLimitRight){
				if(gTx > 0)
					tx = gTx - (period * (gTx > period ? round(gTx / period) : 1));
				else
					tx = gTx + (period * (gTx < -period ? -round(gTx / period) : 1));
			}
			
			// Use the matrixB to render the half of the image on the right side of the screen
			if(gTx > 0)
				matrixB.tx = (tx + (tx >> 31) ^ (tx >> 31)) < this.w ? tx - giWidth : 0; // Apears on the Left side
			else
				matrixB.tx = tx + giWidth;	// Apears on the Right side
			
			//trace("[onTimerXLoop] matrixA.tx: "+matrixA.tx.toFixed(2)+", matrixB.tx: "+matrixB.tx.toFixed(2)+", tx: "+tx.toFixed(2));
		
			// Only draw images if it's on the viewable region
			if ( tx >= xLimitLeft && tx <= xLimitRight){
				matrixA.tx = tx;
				canvasBD.draw(giantImg, matrixA);
			}
			//else trace("[onTimerXLoop] !!! not rendering A !!!");
			
			if ( matrixB.tx >= xLimitLeft && matrixB.tx <= xLimitRight)
				canvasBD.draw(giantImg, matrixB);
			//else trace("[onTimerXLoop] ??? not rendering B ???");
			
			e.updateAfterEvent(); // for immediate rendering!
		}
		
		private function round(n:Number):int
		{
			return n < 0 ? n + .5 == (n | 0) ? n : n - .5 : n + .5;
		}
		
		private function createGTXDisplay():void
		{
			var fontColor:uint =  0x00ff00;
			this.tlGtx = new TextField();
			this.tlGty = new TextField();
			
			tlGtx.defaultTextFormat = new TextFormat('Verdana',14, fontColor);
			tlGtx.autoSize = TextFieldAutoSize.LEFT;
			tlGtx.x = 10;
			tlGtx.y = 10;
			tlGtx.selectable = false;
			
			tlGty.defaultTextFormat = new TextFormat('Verdana',14, fontColor);
			tlGty.autoSize = TextFieldAutoSize.LEFT;
			tlGty.x = 10;
			tlGty.y = 50;
			tlGty.selectable = false;
			
			addChild(tlGtx);
			addChild(tlGty);
		}
	}
}