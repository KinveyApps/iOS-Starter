"use strict";

let commandLineArgs = require('command-line-args');
let Kinvey = require('kinvey');
let Q = require('q');

let cli = commandLineArgs([
    { name: 'help', alias: 'h', type: Boolean, defaultOption: true, defaultValue: false },
    { name: 'appKey', type: String },
    { name: 'appSecret', type: String },
    { name: 'username', alias: 'u', type: String },
    { name: 'password', alias: 'p', type: String },
    { name: 'collection', alias: 'c', type: String, multiple: true },
    { name: 'output', alias: 'o', type: String, multiple: true, defaultOption: true, defaultValue: [ 'filesystem' ] },
    { name: 'limit', alias: 'l', type: Number, defaultValue: 1000 },
]);
let options = cli.parse();

if (options.help || !options.appKey || !options.appSecret) {
    console.log(cli.getUsage());
    exit();
}

let filesystem = require('./filesystem');
let sqlite = require('./sqlite');

let outputs = []
if (options.output.indexOf('filesystem') != -1) {
    outputs.push(filesystem);
}
if (options.output.indexOf('sqlite') != -1) {
    outputs.push(sqlite);
}

Kinvey.init({
    appKey    : options.appKey,
    appSecret : options.appSecret
}).then(function(activeUser) {
    let promise = Kinvey.ping();
    promise.then(function(response) {
        console.log('Kinvey Ping Success. Kinvey Service is alive, version: ' + response.version + ', response: ' + response.kinvey);
    }, function(error) {
        console.error('Kinvey Ping Failed. Response: ' + error.description);
    });
    return promise;
}, function(error) {
    console.error('Kinvey Init Failed:', error);
}).then(function() {
    let promise = Kinvey.User.login(
        options.username, options.password
    );
    promise.then(function(user) {
        console.log('Login succeed!');
        return user;
    }, function(error) {
        console.error('Login failed!:', error);
    });
    return promise;
}).then(function(user) {
    let promises = [];
    outputs.forEach(function(output) {
        let promise = output.open();
        if (promise) {
            promises.push(promise);
        }
    }, this);
    Q.all(promises).then(function() {
        let promises = [];
        options.collection.forEach(function(collection) {
            let promise = fetchCollection('appdata', collection);
            if (promise) {
                promises.push(promise);
            }
        }, this);
        Q.all(promises).then(function() {
            let promises = [];
            outputs.forEach(function(output) {
                let promise = output.close();
                if (promise) {
                    promises.push(promise);
                }
            }, this);
            Q.all(promises).then(function() {
                exit();
            });
        });
    });
});

let startDate = new Date();

function exit() {
    let now = new Date();
    console.log('Start Date:', startDate);
    console.log('  End Date:', now);
    process.exit();
}

function saveEntity(route, collection, entity) {
    let deferred = Q.defer();
    let promises = []
    outputs.forEach(function(output) {
        let promise = output.saveEntity(route, collection, entity);
        if (promise) {
            promises.push(promise);
        }
    }, this);
    Q.all(promises).then(function() {
        deferred.resolve();
    });
    return deferred.promise;
}

function fetchCollection(route, collection) {
    let deferred = Q.defer();
    let promises = [];
    outputs.forEach(function(output) {
        let promise = output.createCollection(route, collection);
        if (promise) {
            promises.push(promise);
        }
    }, this);
    Q.all(promises).then(function() {
        Kinvey.DataStore.group(
            collection, Kinvey.Group.count()
        ).then(function(results) {
            let total = results && results.length > 0 ? results[0].result : 0;
            let skip = 0;
            let callback = function(entities) {
                let promises = [];
                entities.forEach(function(element, index) {
                    let promise = saveEntity(route, collection, element);
                    promise.then(function() {
                        console.log(collection, skip + index + 1, 'of', total);
                    });
                    promises.push(promise);
                }, this);
                Q.all(promises).then(function() {
                    skip += entities.length;
                    if (entities.length == 0) {
                        deferred.resolve();
                    } else {
                        _fetchCollection(
                            route, collection, skip, options.limit
                        ).then(callback);
                    }
                });
            };
            _fetchCollection(
                route, collection, skip, options.limit
            ).then(callback);
        });
    });
    return deferred.promise;
}

function _fetchCollection(route, collection, skip, limit) {
    let query = new Kinvey.Query();
    if (skip) {
        query.skip(skip);
    }
    if (limit) {
        query.limit(limit);
    }
    return Kinvey.DataStore.find(
        collection,
        query
    );
}
