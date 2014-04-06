/*
** © 2013 by Philipp Dunkel <p.dunkel@me.com>. Licensed under MIT License.
*/

var fs = require('fs');
var util = require('util');
var EventEmitter = require('events').EventEmitter;
var binding;
try {
  binding = require('./build/Release/fswatch');
} catch(ex) {
  binding = require('./build/Debug/fswatch');
}
var FSEvents = binding.FSEvents;
util.inherits(FSEvents, EventEmitter);

function getFileType(flags) {
  if (FSEvents.kFSEventStreamEventFlagItemIsFile & flags) return 'file';
  if (FSEvents.kFSEventStreamEventFlagItemIsDir & flags) return 'directory';
  if (FSEvents.kFSEventStreamEventFlagItemIsSymlink & flags) return 'symlink';
}

function getEventType(flags) {
  if (FSEvents.kFSEventStreamEventFlagItemRemoved & flags) return 'deleted';
  if (FSEvents.kFSEventStreamEventFlagItemCreated & flags) return 'created'
  if (FSEvents.kFSEventStreamEventFlagItemRenamed & flags) return 'moved';
  if (FSEvents.kFSEventStreamEventFlagItemModified & flags) return 'modified';
  return 'unknown';
}

function getFileChanges(flags) {
  return {
    inode: !!(FSEvents.kFSEventStreamEventFlagItemInodeMetaMod & flags),
    finder: !!(FSEvents.kFSEventStreamEventFlagItemFinderInfoMod & flags),
    access: !!(FSEvents.kFSEventStreamEventFlagItemChangeOwner & flags),
    xattrs: !!(FSEvents.kFSEventStreamEventFlagItemXattrMod & flags)
  };
}

function getInfo(path, flags) {
  return {
    path: path,
    event: getEventType(flags),
    type: getFileType(flags),
    changes: getFileChanges(flags),
  };
}

function watch(path) {
  var fsevents = new FSEvents(path);

  fsevents.on('fsevent', function(path, flags, id) {
    var info = getInfo(path, flags);
    info.id = id;

    if (info.event == 'moved') {
      fs.stat(info.path, function(err, stat) {
        info.event = (err || !stat) ? 'moved-out' : 'moved-in';
        fsevents.emit('change', path, info);
        fsevents.emit(info.event, path, info);
      });
    } else {
      fsevents.emit('change', path, info);
      if (info.event !== 'unknown') fsevents.emit(info.event, path, info);
    }
  });

  return fsevents;
};

module.exports = watch;
watch.FSEvents = binding.FSEvents;
watch.getInfo = getInfo;
