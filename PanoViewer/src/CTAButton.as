package
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	/**
	 * Call To Action Button. A nice looking button. It makes sure that the text label always fits.
	 */
	public class CTAButton extends Sprite
	{
		protected var params:Object;
		protected var textLabel:TextField;
		protected var clickHandler:Function;
		private var activeColor:uint; // color to use for drawing. based if mouse if over the button or not
		
		public function CTAButton(params:Object)
		{
			super();
			this.params = params;
			init();
		}
		
		protected function init():void
		{
			this.activeColor = params.bkgColor; // start drawing the bkg color
			this.width = params.width;
			this.height = params.height;
			this.clickHandler = params.clickHandler;
			
			// first draw the text label
			this.textLabel = new TextField();
			this.textLabel.defaultTextFormat = new TextFormat('Verdana',params.fontSize, params.fontColor);
			this.textLabel.autoSize = TextFieldAutoSize.LEFT;
			
			this.textLabel.text = String(params.label).toUpperCase();
			trace("[CTAButton.init] textWidth: "+ this.textLabel.textWidth + ', textHeight: ' + this.textLabel.textHeight);
			
			// The button label will determine the position and size of the button
			this.textLabel.x = this.params.x - (this.textLabel.textWidth * .5);
			this.textLabel.y = this.params.y - (this.textLabel.textHeight * .5);
			
			this.textLabel.selectable = false;
			
			// now we can draw the button based on the text dimensions
			drawButton();
			
			this.addChild(textLabel);
			
			// Configure the visual mouse behaviour useHandCursor, buttonMode, and mouseChildren
			this.useHandCursor = true;
			this.buttonMode = true;
			this.mouseChildren = false;
			
			if(clickHandler is Function)
				this.addEventListener(MouseEvent.CLICK, this.clickHandler);
			else
				this.addEventListener(MouseEvent.CLICK, onClick);
			this.addEventListener(MouseEvent.ROLL_OVER, onRollOverHandler);
			this.addEventListener(MouseEvent.ROLL_OUT, onRollOutHandler);
		}
		
		protected function drawButton():void
		{
			this.graphics.clear();
			
			this.graphics.lineStyle(2, this.params.fontColor);
			
			//Set the color of the button graphic depending on the active color
			this.graphics.beginFill(this.activeColor, .5);
			
			//Set the X,Y, Width, and Height of the button graphic
			this.graphics.drawRect(this.textLabel.x  - 10, this.textLabel.y - 10, this.textLabel.textWidth + 25, this.textLabel.textHeight + 23);
			
			//Apply the fill
			this.graphics.endFill();
		}
		
		protected function onRollOutHandler(event:MouseEvent):void
		{
			//trace("[onRollOutHandler]");
			this.activeColor = this.params.bkgColor;
			drawButton();
		}
		
		protected function onRollOverHandler(event:MouseEvent):void
		{
			//trace("[onRollOverHandler]");
			this.activeColor = this.params.overColor;
			drawButton();
		}
		
		protected function onClick(event:MouseEvent):void
		{
			trace("[CTAButton.onClick]");
			navigateToURL(new URLRequest(this.params.url), "_blank");
		}
	}
}