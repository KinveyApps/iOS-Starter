"use strict";

let fs = require('fs');
let path = require('path');

function open() {
}

function close() {
}

function createCollection(route, collection) {
    if (!fs.existsSync(route)) {
        fs.mkdirSync(route);
    }
    let collectionPath = path.join(route, collection);
    if (!fs.existsSync(collectionPath)) {
        fs.mkdirSync(collectionPath);
    }
}

function saveEntity(route, collection, entity) {
    fs.writeFileSync(path.join(route, collection, entity._id), JSON.stringify(entity));
}

module.exports.open = open;
module.exports.createCollection = createCollection;
module.exports.saveEntity = saveEntity;
module.exports.close = close;