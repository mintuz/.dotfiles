var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ('value' in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

var _get = function get(_x, _x2, _x3) { var _again = true; _function: while (_again) { var object = _x, property = _x2, receiver = _x3; _again = false; if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { _x = parent; _x2 = property; _x3 = receiver; _again = true; desc = parent = undefined; continue _function; } } else if ('value' in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } } };

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

function _inherits(subClass, superClass) { if (typeof superClass !== 'function' && superClass !== null) { throw new TypeError('Super expression must either be null or a function, not ' + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

/*
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */

var _flux = require('flux');

var instance = undefined;

var FileTreeDispatcher = (function (_Dispatcher) {
  _inherits(FileTreeDispatcher, _Dispatcher);

  function FileTreeDispatcher() {
    _classCallCheck(this, FileTreeDispatcher);

    _get(Object.getPrototypeOf(FileTreeDispatcher.prototype), 'constructor', this).apply(this, arguments);
  }

  _createClass(FileTreeDispatcher, null, [{
    key: 'getInstance',
    value: function getInstance() {
      if (!instance) {
        instance = new FileTreeDispatcher();
      }
      return instance;
    }
  }]);

  return FileTreeDispatcher;
})(_flux.Dispatcher);

module.exports = FileTreeDispatcher;
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIkZpbGVUcmVlRGlzcGF0Y2hlci5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiOzs7Ozs7Ozs7Ozs7Ozs7O29CQVd5QixNQUFNOztBQUUvQixJQUFJLFFBQWlCLFlBQUEsQ0FBQzs7SUFFaEIsa0JBQWtCO1lBQWxCLGtCQUFrQjs7V0FBbEIsa0JBQWtCOzBCQUFsQixrQkFBa0I7OytCQUFsQixrQkFBa0I7OztlQUFsQixrQkFBa0I7O1dBQ0osdUJBQXVCO0FBQ3ZDLFVBQUksQ0FBQyxRQUFRLEVBQUU7QUFDYixnQkFBUSxHQUFHLElBQUksa0JBQWtCLEVBQUUsQ0FBQztPQUNyQztBQUNELGFBQU8sUUFBUSxDQUFDO0tBQ2pCOzs7U0FORyxrQkFBa0I7OztBQVN4QixNQUFNLENBQUMsT0FBTyxHQUFHLGtCQUFrQixDQUFDIiwiZmlsZSI6IkZpbGVUcmVlRGlzcGF0Y2hlci5qcyIsInNvdXJjZXNDb250ZW50IjpbIid1c2UgYmFiZWwnO1xuLyogQGZsb3cgKi9cblxuLypcbiAqIENvcHlyaWdodCAoYykgMjAxNS1wcmVzZW50LCBGYWNlYm9vaywgSW5jLlxuICogQWxsIHJpZ2h0cyByZXNlcnZlZC5cbiAqXG4gKiBUaGlzIHNvdXJjZSBjb2RlIGlzIGxpY2Vuc2VkIHVuZGVyIHRoZSBsaWNlbnNlIGZvdW5kIGluIHRoZSBMSUNFTlNFIGZpbGUgaW5cbiAqIHRoZSByb290IGRpcmVjdG9yeSBvZiB0aGlzIHNvdXJjZSB0cmVlLlxuICovXG5cbmltcG9ydCB7RGlzcGF0Y2hlcn0gZnJvbSAnZmx1eCc7XG5cbmxldCBpbnN0YW5jZTogP09iamVjdDtcblxuY2xhc3MgRmlsZVRyZWVEaXNwYXRjaGVyIGV4dGVuZHMgRGlzcGF0Y2hlciB7XG4gIHN0YXRpYyBnZXRJbnN0YW5jZSgpOiBGaWxlVHJlZURpc3BhdGNoZXIge1xuICAgIGlmICghaW5zdGFuY2UpIHtcbiAgICAgIGluc3RhbmNlID0gbmV3IEZpbGVUcmVlRGlzcGF0Y2hlcigpO1xuICAgIH1cbiAgICByZXR1cm4gaW5zdGFuY2U7XG4gIH1cbn1cblxubW9kdWxlLmV4cG9ydHMgPSBGaWxlVHJlZURpc3BhdGNoZXI7XG4iXX0=