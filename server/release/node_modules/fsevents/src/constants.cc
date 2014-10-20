/*
** © 2014 by Philipp Dunkel <pip@pipobscure.com>
** Licensed under MIT License.
*/


static v8::Local<v8::Object> Constants() {
  NanEscapableScope();
  v8::Local<v8::Object> object = NanNew<v8::Object>();
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagNone"), NanNew<v8::Integer>(kFSEventStreamEventFlagNone));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagMustScanSubDirs"), NanNew<v8::Integer>(kFSEventStreamEventFlagMustScanSubDirs));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagUserDropped"), NanNew<v8::Integer>(kFSEventStreamEventFlagUserDropped));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagKernelDropped"), NanNew<v8::Integer>(kFSEventStreamEventFlagKernelDropped));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagEventIdsWrapped"), NanNew<v8::Integer>(kFSEventStreamEventFlagEventIdsWrapped));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagHistoryDone"), NanNew<v8::Integer>(kFSEventStreamEventFlagHistoryDone));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagRootChanged"), NanNew<v8::Integer>(kFSEventStreamEventFlagRootChanged));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagMount"), NanNew<v8::Integer>(kFSEventStreamEventFlagMount));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagUnmount"), NanNew<v8::Integer>(kFSEventStreamEventFlagUnmount));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemCreated"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemCreated));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemRemoved"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemRemoved));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemInodeMetaMod"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemInodeMetaMod));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemRenamed"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemRenamed));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemModified"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemModified));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemFinderInfoMod"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemFinderInfoMod));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemChangeOwner"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemChangeOwner));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemXattrMod"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemXattrMod));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemIsFile"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemIsFile));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemIsDir"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemIsDir));
  object->Set(NanNew<v8::String>("kFSEventStreamEventFlagItemIsSymlink"), NanNew<v8::Integer>(kFSEventStreamEventFlagItemIsSymlink));
  return NanEscapeScope(object);
}
