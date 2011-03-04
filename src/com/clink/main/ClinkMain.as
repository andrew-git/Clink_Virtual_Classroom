package com.clink.main
{
	import com.clink.base.Base_componentToolTip;
	import com.clink.controllers.Controller_Dragable;
	import com.clink.events.SharedObjectEvent;
	import com.clink.factories.Factory_prettyBox;
	import com.clink.loaders.EasyXmlLoader;
	import com.clink.loaders.loaderEvents.XmlComplete_Event;
	import com.clink.managers.Manager_remoteCommonSharedObject;
	import com.clink.managers.Manager_remoteUserSharedObject;
	import com.clink.misc.Keys;
	import com.clink.misc.MacMouseWheelHandler;
	import com.clink.ui.BasicButton;
	import com.clink.ui.LayoutBox;
	import com.clink.ui.ScrollBar;
	import com.clink.ui.ScrollBox;
	import com.clink.ui.ScrollList;
	import com.clink.utils.DrawingUtils;
	import com.clink.utils.ParseConfigXML;
	import com.clink.utils.StringUtils;
	import com.clink.valueObjects.VO_Settings;
	
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.media.Camera;
	import flash.net.NetConnection;
	import flash.net.Responder;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	public class ClinkMain extends Sprite
	{
		//netConnection
		private var _nc:NetConnection;
		
		//connection info
		private var _appURL:String;
		private var _username:String;
		private var _classId:String;
		private var _serverUserID:int;
		private var _userPermission:String;
		
		private var _configInfo:VO_Settings;

		//stage
		private var _stage:Stage;
		
		//ui elements
		private var _sidebar:Main_SideBar;
		
		
		//for demo purposes
		private var sl:sampleLogin;
		
		public function ClinkMain(stage:Stage)
		{
			super();

			
			_stage = stage;
			
			//loadConfig();
			
			//this will normally be handled by php, and will be if I have the time.
			setUpSampleLogin();
		}
		
		private function setUpSampleLogin():void
		{
			sl = new sampleLogin();
			sl.x = _stage.stageWidth/2 - sl.width/2;
			sl.y = 100;
			sl.tf_username.maxChars = 15;
			sl.tf_username.multiline = false;
			sl.tf_username.wordWrap = false;
			this.addChild(sl);
			sl.btn_submit.buttonMode = true;
			sl.btn_submit.mouseChildren = false;
			sl.btn_submit.addEventListener(MouseEvent.CLICK, onSubmit);
		}
		
		private function onSubmit(e:MouseEvent):void
		{
			_username = StringUtils.trimLineBreaks(sl.tf_username.text.split(" ").join("_"));
			_username = _username.split(" ").join("");
			this.removeChild(sl);
			loadConfig();
		}
		
		private function loadConfig():void
		{
			//passed in via flash vars or read from database
			//_username = "Adam";
			_userPermission = "teacher";
			
			var xl:EasyXmlLoader = new EasyXmlLoader("config.xml");
			xl.addEventListener(XmlComplete_Event.XML_LOADED,parseConfigXML);
		}
		
		private function init():void
		{	
			_classId = '1';//_configInfo.classId;
			
			//pops up a settings menu asking for camera permission
			Security.showSettings(SecurityPanel.PRIVACY);
			//initialize scrollbars
			ScrollBar.initScrollBars();
			//initialize keyboard class
			Keys.init(_stage);
			//fixes the mac mouse wheel scrolling issue
			MacMouseWheelHandler.init(_stage);
			//init buttons
			BasicButton.init();
			//init tooltips
			Base_componentToolTip.initTooltips(_stage);
			//init sharedObject managers
			Manager_remoteCommonSharedObject.init(_classId);
			Manager_remoteUserSharedObject.init(_classId);
			
			//These values are colors that are set with the config.xml
			BasicButton.isGradient = _configInfo.basicButton_isGradient;
			BasicButton.setButtonColors(_configInfo.basicButton_upStateColor,_configInfo.basicButton_downStateColor,_configInfo.basicButton_overStateColor);
			ScrollBar.setScrollBarColors(_configInfo.scrollBar_buttonColor,_configInfo.scrollBar_trackColor,_configInfo.scrollBar_arrowColor,_configInfo.scrollBar_handleColor);
			Base_componentToolTip.bgColor = _configInfo.toolTip_bgColor;
			Base_componentToolTip.textColor = _configInfo.toolTip_textColor;
			Base_componentToolTip.textSize = _configInfo.toolTip_textSize;
			Base_componentToolTip.toolTipDisplayDelay = _configInfo.toolTip_displayDelay;
			
			_appURL = _configInfo.appURL;
			
			_configInfo.username = _username;
			_configInfo.userPermission = _userPermission;
			
			
			//connect the NetConnection to the Red5 server
			_nc = new NetConnection();
			_nc.client = this;
			_nc.connect(_appURL,_username,_classId);
			_nc.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandler);
			
			_configInfo.netConnection = _nc;
	
		}
		
		//called by the server and assigns a user ID
		public function setUserId(value:*):void
		{
			trace("[Red5][Connect] Your user ID is: "+value);
			_serverUserID = value;
			
			_configInfo.userID = _serverUserID;
			
			//set up ui elements
			setUpSidebar();
			
			
			//testing purposes only////////////////////////////////////////////////////////////////////////////////////
			var _tf:TextField;
			_tf = new TextField();
			_tf.text = _username + "("+ _configInfo.userID + ")";
			_tf.maxChars = 20;
			_tf.height = 14;
			_tf.width = 145;
			_tf.x = 7;
			_tf.y = 4;
			_tf.selectable = false;
			_tf.mouseEnabled = false;
			
			var hv:Font = new HelveticaRegular();
			var _tff1:TextFormat = new TextFormat(hv.fontName,12,0xffffff);
			this.addChild(_tf);
			
			_tf.setTextFormat(_tff1);
			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		}
		
		private function setUpSidebar():void
		{	
			
			_sidebar = new Main_SideBar(_configInfo);
			this.addChild(_sidebar);
			_sidebar.x = (_stage.stageWidth/2 + 960/2) - _sidebar.width;
		
		}
		
		
		//////////////////////////Call backs///////////////////////////////
		
		private function parseConfigXML(e:XmlComplete_Event):void
		{
			_configInfo = ParseConfigXML.parseConfig(e.loadedXML);
			init();
		}
		
		public function onBWDone():void
		{
			
		}
		
		private function netStatusHandler(e:NetStatusEvent):void
		{
			trace(e.info.code);
			if(e.info.code == "NetConnection.Connect.Success")
			{
				///instead of calling a method here after connection success, we call it when the userID gets passed
			}
			
			if(e.info.code == "NetConnection.Connect.Failed")
			{
				trace("connection failed!!");
				
				//display some sort of error message
			}
		}
	}
}