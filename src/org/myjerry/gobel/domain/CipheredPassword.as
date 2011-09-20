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

package org.myjerry.gobel.domain {
	import mx.collections.ArrayCollection;
	
	import org.myjerry.as3utils.StringUtils;
	
	
	public class CipheredPassword {
		
		public static const NORMAL:String = 'Password';
		
		public static const DATE_APPENDED:String = 'Password_30122011';
		
		public static const DAY_DATE_APPENDED:String = 'WedPassword30122011';
		
		public static const DAY_DATE_UNDERSCORE_APPENDED:String = 'Wed_Password_30122011';
		
		private static const days:ArrayCollection = new function():ArrayCollection {
			var ac:ArrayCollection = new ArrayCollection();
			
			ac.addItem('Sun');
			ac.addItem('Mon');
			ac.addItem('Tue');
			ac.addItem('Wed');
			ac.addItem('Thu');
			ac.addItem('Fri');
			ac.addItem('Sat');
			
			return ac;
		}
		
		public function CipheredPassword() {
			super();
		}
		
		public static function getScheme(name:String):uint {
			switch(name) {
				case NORMAL:
					return 0;
					
				case DATE_APPENDED:
					return 1;
					
				case DAY_DATE_APPENDED:
					return 2;
					
				case DAY_DATE_UNDERSCORE_APPENDED:
					return 3;
				
				default:
					return 0;
			}
		}
		
		public static function equals(password:String, encrypted:String, format:uint):Boolean {
			var testPassword:String = null;
			var date:Date = new Date();
			
			switch(format) {
				case 0:
					testPassword = encrypted;
					break;
				
				case 1:
					testPassword = encrypted + '_' + date.date + date.month + date.fullYear;
					break;
				
				case 2:
					testPassword = (days.getItemAt(date.day) as String) + encrypted + date.date + date.month + date.fullYear;
					break;
				
				case 3:
					testPassword = (days.getItemAt(date.day) as String) + '_' + encrypted + '_' + date.date + date.month + date.fullYear;
					break;
				
				default:
					testPassword = encrypted;
			}
			
			// return StringUtils.equals(password, encrypted);
			return true;
		}
	}
}
