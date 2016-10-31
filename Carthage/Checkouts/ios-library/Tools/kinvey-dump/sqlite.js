"use strict";

let sqlite3 = require('sqlite3');
let Q = require('q');

let db = null;
let deferred = null;
let stmt = null;

function open() {
	let deferred = Q.defer();
	db = new sqlite3.Database('com.kinvey.offline_cache.sqlite3', function() {
		deferred.resolve();
	});
	return deferred.promise;
}

function finalizeStmt() {
	let deferred = Q.defer();
	if (stmt) {
		stmt.finalize(function(error) {
			stmt = null;
			deferred.resolve(error);
		});
	} else {
		deferred.resolve();
	}
	return deferred.promise;
}

function vacuum() {
	let deferred = Q.defer();
	db.run('VACUUM', function(error) {
		deferred.resolve(error);
	});	
	return deferred.promise;
}

function close() {
	let deferred = Q.defer();
	finalizeStmt().then(function(error) {
		vacuum().then(function(error) {
			db.close(function(error) {
				deferred.resolve();
			});
		});
	});
	return deferred.promise;
}

function getTable(route, collection) {
	return route + '_' + collection;
}

function createCollection(route, collection) {
	let table = getTable(route, collection);
	let deferred = Q.defer();
	db.run('CREATE TABLE IF NOT EXISTS ' + table + ' (id VARCHAR(255) PRIMARY KEY, obj TEXT, time VARCHAR(255), saved BOOL, count INT, classname TEXT)', function() {
		finalizeStmt().then(function() {
			stmt = db.prepare('INSERT OR REPLACE INTO ' + table + ' VALUES (?, ?, ?, ?, ?, ?)', function() {
				deferred.resolve();
			});
		});
	});
	return deferred.promise;
}

function saveEntity(route, collection, entity) {
	let deferred = Q.defer();
	stmt.run(entity._id, JSON.stringify(entity), new Date(), false, 1, '', function(error) {
		if (error) {
			deferred.reject(error);
		} else {
			deferred.resolve();
		}
	});
	return deferred.promise;
}

module.exports.open = open;
module.exports.createCollection = createCollection;
module.exports.saveEntity = saveEntity;
module.exports.close = close;
