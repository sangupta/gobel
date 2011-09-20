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

package org.myjerry.gobel.store {
	
	import com.adobe.air.crypto.EncryptionKeyGenerator;
	
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.filesystem.File;
	import flash.net.Responder;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	import org.myjerry.as3utils.AssertUtils;
	import org.myjerry.as3utils.ExtendedEncryptedLocalStore;
	import org.myjerry.as3utils.FileUtils;
	import org.myjerry.gobel.domain.ELSKeys;
	import org.myjerry.gobel.domain.StoreFile;
	
	public class StoreManager {
		
		private static const DB_FILENAME:String = 'app-storage:/gobel.db';
		
		private static var initialized:Boolean = false;
		
		public function StoreManager() {
			super();
		}
		
		/**
		 * Shared database connection
		 */
		private static var dbConnection:SQLConnection = null;
		
		public static function initialize():void {
			dbConnection = new SQLConnection();
			
			// create a reference to the database file
			var dbFile:File = new File(DB_FILENAME);
			
			var encryptionPassword:String = ExtendedEncryptedLocalStore.getStringItem(ELSKeys.DATABASE_ENCRYPTION_PASSWORD);
			
			var keyGenerator:EncryptionKeyGenerator = new EncryptionKeyGenerator();
			var encryptionKey:ByteArray = keyGenerator.getEncryptionKey(encryptionPassword);
			
			// create the database if it is not already present
			dbConnection.open(dbFile , SQLMode.CREATE, false, 1024, encryptionKey);
			
			// dbConnection.open(dbFile , SQLMode.CREATE, false, 1024);
			
			beginTransaction();
			
			try {
				// create the required data tables
				var query:String = "CREATE TABLE IF NOT EXISTS files (" +
					"   fileID   			INTEGER PRIMARY KEY AUTOINCREMENT," +
					"   fileName 			TEXT NOT NULL," +
					"   currentVersion		INTEGER NOT NULL," +
					"	UNIQUE (fileName)" +
					")";
				executeSQLQuery(query);
				
				query = "CREATE TABLE IF NOT EXISTS fileVersions (" +
					"	versionID		INTEGER PRIMARY KEY AUTOINCREMENT," +
					"	fileID			INTEGER NOT NULL," +
					"	fileVersion		INTEGER NOT NULL," +
					"	size			INTEGER NOT NULL," +
					"	lastModified	DATE NOT NULL," +
					"	storedOn		DATE NOT NULL," +
					"	UNIQUE(fileID, fileVersion)" +
					")";
				executeSQLQuery(query);
				
				query = "CREATE TABLE IF NOT EXISTS fileData (" +
					"	fileDataID		INTEGER PRIMARY KEY AUTOINCREMENT," +
					"	versionID		INTEGER NOT NULL," +
					"	fileData		BLOB NOT NULL," +
					"	UNIQUE (versionID)" +
					")";
				executeSQLQuery(query);
				
				// commit DB changes
				commitTransaction();
			} catch(e:Error) {
				// roll back
				rollbackTransaction();
				
				Alert.show("Unable to initialize the database. Contact the application developer.");
			}
		}
		
		public static function getFilesInStore():ArrayCollection {
			if(!initialized) {
				initialize();
			}

			var statement:SQLStatement = getStatement("SELECT * FROM files f, fileVersions fv WHERE f.fileID = fv.fileID AND f.currentVersion = fv.fileVersion");
			statement.execute();
			var result:SQLResult = statement.getResult();
			
			if(result != null && result.data != null && result.data.length > 0) {
				var arrayCollection:ArrayCollection = new ArrayCollection();

				for(var index:int = 0; index < result.data.length; index++) {
					var row:Object = result.data[index];
					
					var storeFile:StoreFile = new StoreFile();
					storeFile.fileName = row.fileName as String;
					storeFile.fileID = row.fileID as uint;
					storeFile.fileVersionID = row.versionID as uint;
					storeFile.lastModified = row.lastModified as Date;
					storeFile.size = row.size as uint;
					storeFile.version = row.fileVersion as uint;
					storeFile.storedOn = row.storedOn as Date;
					
					arrayCollection.addItem(storeFile);
				}
				
				return arrayCollection;
			}

			return null;
		}
		
		public static function importFileInStore(fileToImport:File):Boolean {
			if(!initialized) {
				initialize();
			}
			
			if(fileToImport == null) {
				return false;
			}
			
			// start importing the file
			const fileName:String = fileToImport.name;
			const size:uint = fileToImport.size;
			const lastModified:Date = fileToImport.modificationDate;
			
			beginTransaction();
			
			try {
				// check if the file already exists in the store
				var exists:Boolean = fileExists(fileName);
				
				const versionID:uint = createFileVersion(fileName, size, lastModified);
					
				// store the file against the ID
				const fileDataID:uint = storeFileInDatabase(versionID, fileToImport);
				
				// commit
				commitTransaction();
				
				return true;
			} catch(e:Error) {
				// roll back
				rollbackTransaction();
			}
			
			return false;
		}
		
		public static function fetchFileFromStore(fileVersionID:uint):ByteArray {
			if(!initialized) {
				initialize();
			}
			
			var statement:SQLStatement = getStatement("SELECT fileData AS value FROM fileData WHERE versionID = :versionID");
			statement.parameters[':versionID'] = fileVersionID;
			statement.execute();
			var result:SQLResult = statement.getResult(); 
			if(result != null && result.data != null) {
				return result.data[0].value as ByteArray;
			}
			
			return null;
		}
		
		public static function getFileVersions(fileID:uint):ArrayCollection {
			if(!initialized) {
				initialize();
			}
			
			if(fileID == 0) {
				return null;
			}
			
			var statement:SQLStatement = getStatement("SELECT * FROM fileVersions WHERE fileID = :fileID");
			statement.parameters[':fileID'] = fileID;
			statement.execute();
			var result:SQLResult = statement.getResult();
			
			if(result != null && result.data != null && result.data.length > 0) {
				var arrayCollection:ArrayCollection = new ArrayCollection();
				
				for(var index:int = 0; index < result.data.length; index++) {
					var row:Object = result.data[index];
					
					var storeFile:StoreFile = new StoreFile();
					storeFile.fileVersionID = row.versionID as uint;
					storeFile.lastModified = row.lastModified as Date;
					storeFile.size = row.size as uint;
					storeFile.version = row.fileVersion as uint;
					storeFile.storedOn = row.storedOn as Date;
					
					arrayCollection.addItem(storeFile);
				}
				
				return arrayCollection;
			}
			
			return null;
		}
		
		protected static function fileExists(name:String):Boolean {
			if(AssertUtils.isEmptyString(name)) {
				return false;
			}
			
			var statement:SQLStatement = getStatement("SELECT COUNT(*) AS value FROM files WHERE fileName = :fileName");
			statement.parameters[':fileName'] = name;
			statement.execute();
			var result:SQLResult = statement.getResult(); 
			if(result != null && result.data != null) {
				if(result.data[0].value > 0) {
					return true;
				}
			}
			return false;
		}
		
		protected static function storeFileInDatabase(version:uint, fileToStore:File):uint {
			var byteArray:ByteArray = FileUtils.readFileToByteArray(fileToStore);
			
			if(byteArray != null) {
				var statement:SQLStatement = getStatement("INSERT INTO fileData (versionID, fileData) VALUES (:versionID, :fileData)");
				statement.parameters[':versionID'] = version;
				statement.parameters[':fileData'] = byteArray;
				statement.execute();
				
				statement = getStatement("SELECT fileDataID AS value FROM fileData WHERE versionID = :versionID");
				statement.parameters[':versionID'] = version;
				statement.execute();
				var result:SQLResult = statement.getResult(); 
				if(result != null && result.data != null) {
					return result.data[0].value as uint;
				}
			}
			
			return 0;
		}
		
		private static function createFileVersion(name:String, size:uint, lastModified:Date):uint {
			var statement:SQLStatement = null;

			var fileID:uint = getFileIdentifier(name);
			if(fileID == 0) {
				statement = getStatement("INSERT INTO files (fileName, currentVersion) VALUES (:fileName, :currentVersion)");
				statement.parameters[':fileName'] = name;
				statement.parameters[':currentVersion'] = 1;
				statement.execute();

				// re-fetch the value from DB
				fileID = getFileIdentifier(name);
			}
			
			var version:uint = getMaxFileVersion(fileID);
			
			statement = getStatement("INSERT INTO fileVersions (fileID, fileVersion, size, lastModified, storedOn) VALUES (:fileID, :fileVersion, :size, :lastModified, :storedOn)");
			statement.parameters[':fileID'] = fileID;
			statement.parameters[':fileVersion'] = (version + 1);
			statement.parameters[':size'] = size;
			statement.parameters[':lastModified'] = lastModified;
			statement.parameters[':storedOn'] = new Date();
			statement.execute();
			
			version = getMaxFileVersion(fileID);
			
			if(version != 1) {
				statement = getStatement("UPDATE files SET currentVersion = :currentVersion WHERE fileID = :fileID");
				statement.parameters[':currentVersion'] = version;
				statement.parameters[':fileID'] = fileID;
				statement.execute();
			}
			
			return getMaxFileVersionID(fileID);
		}
		
		protected static function getMaxFileVersion(fileID:uint):uint {
			var statement:SQLStatement = getStatement("SELECT MAX(fileVersion) AS value FROM fileVersions WHERE fileID = :fileID");
			statement.parameters[':fileID'] = fileID;
			statement.execute();
			var result:SQLResult = statement.getResult();
			
			if(result != null && result.data != null) {
				return result.data[0].value as uint;
			}
			
			return 0;
		}
		
		protected static function getMaxFileVersionID(fileID:uint):uint {
			const maxVersion:uint = getMaxFileVersion(fileID);
			
			var statement:SQLStatement = getStatement("SELECT versionID AS value FROM fileVersions WHERE fileID = :fileID and fileVersion = :fileVersion");
			statement.parameters[':fileID'] = fileID;
			statement.parameters[':fileVersion'] = maxVersion;
			statement.execute();
			var result:SQLResult = statement.getResult();
			
			if(result != null && result.data != null) {
				return result.data[0].value as uint;
			}
			
			return 0;
		}
		
		protected static function getFileIdentifier(name:String):uint {
			var statement:SQLStatement = getStatement("SELECT fileID AS value FROM files WHERE fileName = :fileName");
			statement.parameters[':fileName'] = name;
			statement.execute();
			var result:SQLResult = statement.getResult();
			
			if(result != null && result.data != null) {
				return result.data[0].value;
			}
			
			return 0;
		}
		
		/**
		 * Database related functions follow
		 */
		
		protected static function executeSQLQuery(statement:String):SQLResult {
			if(dbConnection != null && dbConnection.connected && AssertUtils.isNotEmptyString(statement)) {
				try {
					var sqlStatement:SQLStatement = new SQLStatement();
					sqlStatement.sqlConnection = dbConnection;
					sqlStatement.text = statement ;
					sqlStatement.execute();
					return sqlStatement.getResult();
				} catch(e:Error) {
					trace("Error executing DB statement: " + statement + "\nError caught: " + e.toString());
				}
			}
			return null;
		}
		
		protected static function getStatement(query:String):SQLStatement {
			if(AssertUtils.isEmptyString(query)) {
				throw new Error('Query cannot be null/empty.');
			}
			
			var statement:SQLStatement = new SQLStatement();
			statement.sqlConnection = dbConnection;
			statement.text = query;
			return statement;
		}
		
		protected static function beginTransaction(option:String = null, responder:Responder = null):void {
			dbConnection.begin(option, responder);
		}
		
		protected static function commitTransaction(responder:Responder = null):void {
			dbConnection.commit(responder);
		}
		
		protected static function rollbackTransaction(responder:Responder = null):void {
			dbConnection.rollback(responder);
		}
	}
}
