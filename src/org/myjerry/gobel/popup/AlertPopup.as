/**
 *
 * gobel - A secured and versioned personal document store.
 * Copyright (C) 2011, myJerry Developers
 * http://www.myjerry.org/gobel
 *
 * The file is licensed under the the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

package org.myjerry.gobel.popup {
	import flash.display.DisplayObject;
	
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	import org.myjerry.as3utils.ArrayUtils;
	
	
	public class AlertPopup {
		
		public function AlertPopup() {
			super();
		}
		
		private static const alerts:Array = new Array;
		
		public static function showAlert(text:String = "", okButtonHandler:Function = null, cancelButtonHandler:Function = null, parent:DisplayObject = null, windowTitle:String = "", okButtonLabel:String = "", cancelButtonLabel:String = ""):void {
			var title:String = '';
			
			if(ArrayUtils.contains(alerts, text)) {
				// the alert is already open - don't need to create a new one
				return;
			}
			
			alerts.push(text);
			
			var flags:uint = 0x4;
			if(cancelButtonHandler != null) {
				flags = flags | UserAlertWindow.CANCEL;
			}
			
			if(parent == null) {
				parent = FlexGlobals.topLevelApplication as DisplayObject;
			}
			
			UserAlertWindow.show(text, parent, title, flags, windowTitle,okButtonLabel,cancelButtonLabel,function myCloseHandler(event:CloseEvent, alertWindow:UserAlertWindow):void {
				if(alertWindow != null) {  
					ArrayUtils.removeItem(alerts, alertWindow.text);
				}
				
				if(event.detail == UserAlertWindow.OK) {
					if(okButtonHandler != null) {
						okButtonHandler(event);
					}
				} else if(event.detail == UserAlertWindow.CANCEL) {
					if(cancelButtonHandler != null) {
						cancelButtonHandler(event);
					}
				}
			}); 
		}
	}
}
