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

package org.myjerry.gobel {

	import org.myjerry.essentials.Essentials;
	import org.myjerry.gobel.domain.DBPreferenceKeys;
	
	public class ApplicationContext {
		
		public function ApplicationContext() {
			super();
		}
		
		public static function get appSetupComplete():Boolean {
			return Essentials.preferences.getBooleanPreference(DBPreferenceKeys.APP_SETUP_COMPLETE, false);
		}
	}
}