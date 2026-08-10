'use strict';

const paths = require('path');
const fs = require('fs');
const fsevents = require('fsevents');

module.exports = function (directoryPath, callback) {
  const foundPaths = {};
  let closed = true;
  let stopWatching = null;

  const init = () => {
    if (!fs.existsSync(directoryPath)) {
      throw new Error(`could not find ${directoryPath}`);
    }

    closed = false;
    stopWatching = fsevents.watch(directoryPath, (filePath, flags, id) => {
      if (closed) return;
      const info = fsevents.getInfo(filePath, flags, id);
      switch (info.event) {
        case 'modified':
        case 'created':
          findFiles(filePath, info.type, registerFile);
          break;
        case 'deleted':
          unregisterFiles(filePath);
          break;
        case 'moved':
          unregisterFiles(filePath);
          findFiles(filePath, info.type, registerFile);
          break;
      }
    });

    console.log('watching', directoryPath);

    findFiles(directoryPath, 'directory', registerFile);
    return close;
  };

  const close = () => {
    closed = true;
    if (stopWatching) stopWatching();
  };

  const registerFile = (filePath) => {
    filePath = filePath.normalize();
    foundPaths[filePath] = true;
    callback({
      type: 'added',
      filePath: filePath.normalize(),
      rootPath: directoryPath,
    });
  };

  const unregisterFiles = (path) => {
    path = path.normalize();
    for (const filePath of Object.keys(foundPaths)) {
      if (filePath.indexOf(path) === 0) {
        callback({type: 'removed', filePath, rootPath: directoryPath});
      }
    }
  };

  // recursively walks the directory tree and calls onFound for every file it
  // finds
  const findFiles = (path, type, onFound) => {
    if (type === 'file') {
      onFound(path);
    } else {
      fs.readdir(path, (err, subPaths) => {
        if (err) return console.log(err);
        for (const subPath of subPaths) {
          const fullPath = paths.join(path, subPath);
          getPathType(fullPath, (p, t) => findFiles(p, t, onFound));
        }
      });
    }
  };

  // get type of path as either 'file' or 'directory'
  // callback gets called with (path, type) where path is the path passed in,
  // for convenience
  const getPathType = (path, callback) => fs.stat(path, (err, stat) => {
    if (err) return console.log(err);
    const type = stat.isDirectory() ? 'directory' : 'file';
    callback(path, type);
  });

  return init();
};
