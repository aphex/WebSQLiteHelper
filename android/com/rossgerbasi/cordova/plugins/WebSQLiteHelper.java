package com.rossgerbasi.cordova.plugins;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteException;
import org.apache.cordova.api.Plugin;
import org.apache.cordova.api.PluginResult;
import org.json.JSONArray;

import java.io.*;

/**
 * User: Ross
 * Date: 7/20/12
 * Time: 7:15 PM
 */
public class WebSQLiteHelper extends Plugin {
	private static String MASTER_DB_FILE = "Databases.db";
	private String dbPath;
	private String masterDbFullPath;

	/**
	 * Sets the path to the this applications databases
	 *
	 * @param ctx
	 */
	@Override
	public void setContext(org.apache.cordova.api.CordovaInterface ctx) {
		this.dbPath = "/data/data/" + ctx.getContext().getPackageName() + "/app_database";
		this.masterDbFullPath = this.dbPath + "/" + MASTER_DB_FILE;
		super.setContext(ctx);
	}

	/**
	 * Cordova Execute
	 *
	 * @param s
	 * @param jsonArray
	 * @param s1
	 * @return
	 */
	@Override
	public PluginResult execute(String s, JSONArray jsonArray, String s1) {
		if (s.equals("create")) {
			try {
				String dbName = jsonArray.getString(0);
				String file = jsonArray.getString(1);
				return this.doCreate(dbName, file);
			} catch (Exception e) {
				return new PluginResult(PluginResult.Status.ERROR, "Error Creating Database");
			}
		} else if (s.equals("checkExistence")) {
			try {
				String dbName = jsonArray.getString(0);
				return this.doCheckExistence(dbName);
			} catch (Exception e) {
				return new PluginResult(PluginResult.Status.ERROR, "Error Checking Existence of Database");
			}
		}
		return new PluginResult(PluginResult.Status.ERROR, "Error unknown Command");
	}

	private  String getDatabasePath(String dbName){
		String path = null;
		SQLiteDatabase db = this.getMasterDatabase();
		if(db == null) return path;

		//Is there no Databases Table
		Cursor c = db.query("sqlite_master", new String[]{"name"}, "type=? AND name IS ?", new String[]{"table", "Databases"}, null, null, null, null);
		if (c.getCount() > 0) {
			//Check for database in master
			c = db.query("Databases", new String[]{"origin", "name", "path"}, "name IS ?", new String[]{dbName}, null, null, null, null);
			if (c.getCount() > 0) {
				c.moveToNext();
				String aOrigin = c.getString(c.getColumnIndex("origin"));
				String aPath = c.getString(c.getColumnIndex("path"));
				try {
					path = this.dbPath + "/" + aOrigin + "/" +aPath;
					db.close();
				} catch (Exception e) { }
			}
		}
		return path;
	}

	private PluginResult doCreate(String dbName, String file) {
		SQLiteDatabase db = this.getMasterDatabase();
		PluginResult pluginResult;
		if (db == null) {
			pluginResult = new PluginResult(PluginResult.Status.ERROR, "Error Master Database Doesn't Exist");
		}else{
			String dest_path = this.getDatabasePath(dbName);
			if(dest_path == null){
				pluginResult = new PluginResult(PluginResult.Status.ERROR, "Error Database Was not Initialized");
			}else{
				try {
					String src_file = "www/" + file;
					copy(src_file, dest_path);
					pluginResult =  new PluginResult(PluginResult.Status.OK);
				}catch(Exception e){
					pluginResult = new PluginResult(PluginResult.Status.ERROR, "Error Copying File");
				}
			}
		}
		return pluginResult;
	}

	private PluginResult doCheckExistence(String dbName) {
		String path = this.getDatabasePath(dbName);
		PluginResult pluginResult;

		if(path == null) {
			pluginResult = new PluginResult(PluginResult.Status.OK, false);
		}else{
			try {
				File db_file = new File(path);
				pluginResult = new PluginResult(PluginResult.Status.OK, db_file.exists());
			} catch (Exception e) {
				pluginResult = new PluginResult(PluginResult.Status.ERROR, "Error Checking File Location");
			}
		}

		return pluginResult;
	}

	/**
	 * Gets a SQLiteDatabase instance of the master Database
	 *
	 * @return Instance of the Master Database or NULL
	 */
	private SQLiteDatabase getMasterDatabase() {
		SQLiteDatabase db = null;
		try {
			db = SQLiteDatabase.openOrCreateDatabase(this.masterDbFullPath, null);
		} catch (SQLiteException e) {
			//database does't exist yet.
		}
		return db;
	}

	/**
	 * Copys a source file into a folder with a given filename
	 *
	 * @param src_file    source file to copy
	 * @param dest_file   destination filename
	 * @throws IOException
	 */
	void copy(String src_file, String dest_file) throws IOException {
		InputStream in = this.ctx.getApplicationContext().getAssets().open(src_file);
		OutputStream out = new FileOutputStream(dest_file);

		// Transfer bytes from in to out
		byte[] buf = new byte[1024];
		int len;
		while ((len = in.read(buf)) > 0) out.write(buf, 0, len);
		in.close();
		out.close();
	}
}
