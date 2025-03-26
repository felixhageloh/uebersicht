window.__UBCallbacks__ = (function () {
    var api = {};
    var callbacks = {};
    var currentId = 0;
    
    api.register = function register(callback) {
        var id = currentId++;
        callbacks[id] = callback;
        
        return id;
    };
    
    api.remove = function remove(id) {
        delete callbacks[id];
    };
    
    api.call = function call(id) {
        if (callbacks[id]) {
            callbacks[id].apply(
                null,
                Array.prototype.slice.apply(arguments, [1])
            );
        }
    };

    return api;
}());

(function() {
    var geolocation = window.navigator.geolocation;
    var messageHandler = window.webkit.messageHandlers.geolocation;

    geolocation.getCurrentPosition = function getCurrentPosition(onPos, onErr) {
        var callbackId = __UBCallbacks__.register(function (pos) {
            onPos(pos);
            __UBCallbacks__.remove(callbackId);
            geolocation.clearWatch(callbackId);
        })
 
        messageHandler.postMessage({
            type: 'registerCallback',
            callbackId: callbackId
        });
    };

    geolocation.watchPosition = function watchPosition(onPos, onErr) {
        var callbackId = __UBCallbacks__.register(function (pos) {
            onPos(pos);
        })
 
        messageHandler.postMessage({
            type: 'registerCallback',
            callbackId: callbackId
        });
 
        return callbackId;
    };
 
     geolocation.clearWatch = function clearWatch(callbackId) {
        messageHandler.postMessage({
            type: 'removeCallback',
            callbackId: callbackId
        });
     }
 
     window.geolocation = geolocation;
}());
