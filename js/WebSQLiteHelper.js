function WebSQLiteHelper() {
	console.log("Created SQLite Helper");
}

WebSQLiteHelper.prototype.create = function (obj) {
	var dbName = obj.name || "default";
	var version = obj.version || "0";
	var displayName = obj.displayName || "Default DB";
	var estimatedSize = obj.estimatedSize || 5 * 1024 * 1024;
	var file = obj.file || null;
	var overwrite = obj.overwrite || false;
	var success = obj.success || function () {};
	var fail = obj.fail || function () {};

	window.plugins.sqlitehelper.dbExists(
			dbName,
			function (exists) {
				var db = openDatabase(dbName, version, displayName, estimatedSize);
				var cordova_success = function () {
					db = openDatabase(dbName, version, displayName, estimatedSize);
					success.apply(this, [db]);
				};

				if ((!exists || overwrite) && file != null) {
					cordova.exec(cordova_success, fail, 'WebSQLiteHelper', 'create', [dbName, file]);
				} else {
					if (db) {
						cordova_success();
					} else {
						fail();
					}
				}
			},
			fail
	);
};

WebSQLiteHelper.prototype.dbExists = function (dbName, success, fail) {
	cordova.exec(success, fail, 'WebSQLiteHelper', 'checkExistence', [dbName]);
};

WebSQLiteHelper.install = function () {
	if (!window.plugins) window.plugins = {};
	window.plugins.sqlitehelper = new WebSQLiteHelper();
};

cordova.addConstructor(WebSQLiteHelper.install);